import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../models/snippet.dart';
import '../services/database_service.dart';

class SnippetRepository {
  SnippetRepository({DatabaseService? db}) : _db = db ?? DatabaseService.instance;

  final DatabaseService _db;
  static const _uuid = Uuid();

  Future<Snippet> create({
    required String name,
    required String content,
    required ClipCategory category,
    String? shortcut,
  }) async {
    final now = DateTime.now();
    final snippet = Snippet(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? 'Untitled snippet' : name.trim(),
      content: content,
      category: category,
      shortcut: (shortcut != null && shortcut.trim().isEmpty) ? null : shortcut,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _db.database;
    await db.insert('snippets', snippet.toMap());
    return snippet;
  }

  Future<List<Snippet>> getAll({String? searchQuery}) async {
    final db = await _db.database;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      final rows = await db.query(
        'snippets',
        where: 'name LIKE ? OR content LIKE ?',
        whereArgs: [q, q],
        orderBy: 'pinned DESC, updated_at DESC',
      );
      return rows.map(Snippet.fromMap).toList();
    }
    final rows = await db.query('snippets', orderBy: 'pinned DESC, updated_at DESC');
    return rows.map(Snippet.fromMap).toList();
  }

  Future<void> update(Snippet snippet) async {
    final db = await _db.database;
    await db.update(
      'snippets',
      snippet.toMap(),
      where: 'id = ?',
      whereArgs: [snippet.id],
    );
  }

  Future<void> setPinned(String id, bool pinned) async {
    final db = await _db.database;
    await db.update(
      'snippets',
      {'pinned': pinned ? 1 : 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('snippets', where: 'id = ?', whereArgs: [id]);
  }
}
