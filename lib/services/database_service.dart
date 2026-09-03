import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Owns the single SQLite connection used by the whole app.
///
/// IMPORTANT (privacy): this service never logs clipboard content. Only
/// row counts / ids / error types are ever written to the log.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  /// Test-only constructor: wraps an already-open database (e.g. an
  /// in-memory sqflite_common_ffi database) so repositories can be unit
  /// tested without touching the real user data file.
  @visibleForTesting
  DatabaseService.forTesting(Database db) : _db = db;

  Database? _db;
  bool _ffiInitialized = false;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    if (!_ffiInitialized && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
    }

    final dir = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(dir.path, 'ClipHold'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final dbPath = p.join(dbDir.path, 'cliphold.db');

    try {
      return await openDatabase(
        dbPath,
        version: 1,
        onCreate: _onCreate,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      developer.log('Failed to open database', name: 'ClipHold.DB', error: e);
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) => createSchema(db);

  /// Creates the full ClipHold schema (tables, indexes, FTS5 virtual
  /// table + sync triggers) on a freshly opened database. Public/static so
  /// tests can build an identical in-memory database via
  /// `DatabaseService.forTesting`.
  static Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE clips (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        pinned INTEGER NOT NULL DEFAULT 0,
        content_hash TEXT NOT NULL,
        copy_count INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('CREATE INDEX idx_clips_hash ON clips(content_hash)');
    await db.execute('CREATE INDEX idx_clips_created ON clips(created_at)');
    await db.execute('CREATE INDEX idx_clips_pinned ON clips(pinned)');
    await db.execute('CREATE INDEX idx_clips_category ON clips(category)');

    await db.execute('''
      CREATE TABLE snippets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        shortcut TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        pinned INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_snippets_name ON snippets(name)');

    // Full-text search over clip content for fast offline search.
    await db.execute('''
      CREATE VIRTUAL TABLE clips_fts USING fts5(
        id UNINDEXED,
        content,
        content='clips',
        content_rowid='rowid'
      )
    ''');
    await db.execute('''
      CREATE TRIGGER clips_ai AFTER INSERT ON clips BEGIN
        INSERT INTO clips_fts(rowid, id, content) VALUES (new.rowid, new.id, new.content);
      END;
    ''');
    await db.execute('''
      CREATE TRIGGER clips_ad AFTER DELETE ON clips BEGIN
        INSERT INTO clips_fts(clips_fts, rowid, id, content) VALUES('delete', old.rowid, old.id, old.content);
      END;
    ''');
    await db.execute('''
      CREATE TRIGGER clips_au AFTER UPDATE ON clips BEGIN
        INSERT INTO clips_fts(clips_fts, rowid, id, content) VALUES('delete', old.rowid, old.id, old.content);
        INSERT INTO clips_fts(rowid, id, content) VALUES (new.rowid, new.id, new.content);
      END;
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Permanently wipes all clipboard history (used by Clear History).
  /// Snippets are intentionally untouched.
  Future<void> clearAllClips() async {
    final db = await database;
    await db.delete('clips');
  }
}
