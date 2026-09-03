import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/clip_item.dart';
import '../models/enums.dart';
import '../services/database_service.dart';
import '../utils/category_detector.dart';

/// All persistence logic for clipboard history. Screens/providers never
/// touch SQL directly.
class ClipboardRepository {
  ClipboardRepository({DatabaseService? db})
      : _db = db ?? DatabaseService.instance;

  final DatabaseService _db;
  static const _uuid = Uuid();

  /// Captures a newly copied piece of content.
  ///
  /// If the exact same normalized content already exists as the most
  /// recent entry (or exists anywhere and was copied again), the existing
  /// row is bumped (updated_at + copy_count) instead of inserting a new
  /// row, preventing duplicate spam from repeated Ctrl+C of the same text.
  ///
  /// Returns the resulting [ClipItem], or null if content was empty/whitespace.
  Future<ClipItem?> captureClip(String rawContent) async {
    final normalized = CategoryDetector.normalize(rawContent);
    if (normalized.isEmpty) return null;

    final hash = CategoryDetector.hash(normalized);
    final db = await _db.database;

    final existingRows = await db.query(
      'clips',
      where: 'content_hash = ?',
      whereArgs: [hash],
      limit: 1,
    );

    final now = DateTime.now();

    if (existingRows.isNotEmpty) {
      final existing = ClipItem.fromMap(existingRows.first);
      final updated = existing.copyWith(
        updatedAt: now,
        copyCount: existing.copyCount + 1,
      );
      await db.update(
        'clips',
        {
          'updated_at': now.millisecondsSinceEpoch,
          'copy_count': updated.copyCount,
        },
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return updated;
    }

    final item = ClipItem(
      id: _uuid.v4(),
      content: normalized,
      category: CategoryDetector.detect(normalized),
      createdAt: now,
      updatedAt: now,
      pinned: false,
      contentHash: hash,
      copyCount: 1,
    );
    await db.insert('clips', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return item;
  }

  Future<List<ClipItem>> getAll({
    ClipCategory? category,
    bool? pinnedOnly,
    String? searchQuery,
    int limit = 500,
  }) async {
    final db = await _db.database;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      return _search(searchQuery.trim(),
          category: category, pinnedOnly: pinnedOnly, limit: limit);
    }

    final where = <String>[];
    final args = <Object?>[];
    if (category != null) {
      where.add('category = ?');
      args.add(category.dbValue);
    }
    if (pinnedOnly == true) {
      where.add('pinned = 1');
    }

    final rows = await db.query(
      'clips',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'pinned DESC, updated_at DESC',
      limit: limit,
    );
    return rows.map(ClipItem.fromMap).toList();
  }

  Future<List<ClipItem>> _search(
    String query, {
    ClipCategory? category,
    bool? pinnedOnly,
    int limit = 500,
  }) async {
    final db = await _db.database;
    // Escape FTS special characters by quoting the whole query as a phrase
    // prefix search; this keeps arbitrary user input (URLs, code) safe.
    final sanitized = query.replaceAll('"', '""');
    final ftsQuery = '"$sanitized"*';

    final where = <String>['clips.id IN (SELECT id FROM clips_fts WHERE clips_fts MATCH ?)'];
    final args = <Object?>[ftsQuery];

    if (category != null) {
      where.add('category = ?');
      args.add(category.dbValue);
    }
    if (pinnedOnly == true) {
      where.add('pinned = 1');
    }

    try {
      final rows = await db.rawQuery('''
        SELECT clips.* FROM clips
        WHERE ${where.join(' AND ')}
        ORDER BY pinned DESC, updated_at DESC
        LIMIT ?
      ''', [...args, limit]);
      return rows.map(ClipItem.fromMap).toList();
    } catch (_) {
      // Fallback to a plain LIKE search if FTS query syntax fails on
      // unusual input (e.g. content that breaks the MATCH grammar).
      final likeWhere = <String>['content LIKE ?'];
      final likeArgs = <Object?>['%$query%'];
      if (category != null) {
        likeWhere.add('category = ?');
        likeArgs.add(category.dbValue);
      }
      if (pinnedOnly == true) {
        likeWhere.add('pinned = 1');
      }
      final rows = await db.query(
        'clips',
        where: likeWhere.join(' AND '),
        whereArgs: likeArgs,
        orderBy: 'pinned DESC, updated_at DESC',
        limit: limit,
      );
      return rows.map(ClipItem.fromMap).toList();
    }
  }

  Future<void> setPinned(String id, bool pinned) async {
    final db = await _db.database;
    await db.update(
      'clips',
      {'pinned': pinned ? 1 : 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateCategory(String id, ClipCategory category) async {
    final db = await _db.database;
    await db.update(
      'clips',
      {
        'category': category.dbValue,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateContent(String id, String newContent) async {
    final normalized = CategoryDetector.normalize(newContent);
    final db = await _db.database;
    await db.update(
      'clips',
      {
        'content': normalized,
        'content_hash': CategoryDetector.hash(normalized),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('clips', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll({bool keepPinned = true}) async {
    final db = await _db.database;
    if (keepPinned) {
      await db.delete('clips', where: 'pinned = 0');
    } else {
      await db.delete('clips');
    }
  }

  /// Deletes unpinned clips older than the retention window. Pinned clips
  /// are always preserved regardless of age.
  Future<int> applyRetention(RetentionPolicy policy) async {
    final duration = policy.duration;
    if (duration == null) return 0;
    final cutoff = DateTime.now().subtract(duration).millisecondsSinceEpoch;
    final db = await _db.database;
    return db.delete(
      'clips',
      where: 'pinned = 0 AND updated_at < ?',
      whereArgs: [cutoff],
    );
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM clips');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
