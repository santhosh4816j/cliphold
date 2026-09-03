import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cliphold/models/enums.dart';
import 'package:cliphold/repositories/snippet_repository.dart';
import 'package:cliphold/services/database_service.dart';

Future<DatabaseService> _newInMemoryDb() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await DatabaseService.createSchema(db);
  return DatabaseService.forTesting(db);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SnippetRepository repo;

  setUp(() async {
    final db = await _newInMemoryDb();
    repo = SnippetRepository(db: db);
  });

  test('create adds a snippet retrievable via getAll', () async {
    final s = await repo.create(
      name: 'Email Signature',
      content: 'Regards,\nSanthosh',
      category: ClipCategory.text,
    );
    final all = await repo.getAll();
    expect(all.length, 1);
    expect(all.first.id, s.id);
    expect(all.first.name, 'Email Signature');
  });

  test('blank name falls back to Untitled snippet', () async {
    final s = await repo.create(name: '  ', content: 'x', category: ClipCategory.text);
    expect(s.name, 'Untitled snippet');
  });

  test('update modifies content and name', () async {
    final s = await repo.create(name: 'A', content: 'first', category: ClipCategory.text);
    final updated = s.copyWith(name: 'B', content: 'second', updatedAt: DateTime.now());
    await repo.update(updated);
    final all = await repo.getAll();
    expect(all.first.name, 'B');
    expect(all.first.content, 'second');
  });

  test('setPinned marks a snippet pinned', () async {
    final s = await repo.create(name: 'A', content: 'x', category: ClipCategory.text);
    await repo.setPinned(s.id, true);
    final all = await repo.getAll();
    expect(all.first.pinned, true);
  });

  test('delete removes a snippet', () async {
    final s = await repo.create(name: 'A', content: 'x', category: ClipCategory.text);
    await repo.delete(s.id);
    final all = await repo.getAll();
    expect(all, isEmpty);
  });

  test('search matches by name or content', () async {
    await repo.create(name: 'Greeting', content: 'Hello there', category: ClipCategory.text);
    await repo.create(name: 'Farewell', content: 'Goodbye now', category: ClipCategory.text);
    final results = await repo.getAll(searchQuery: 'Hello');
    expect(results.length, 1);
    expect(results.first.name, 'Greeting');
  });

  test('pinned snippets are sorted first', () async {
    await repo.create(name: 'Unpinned', content: 'x', category: ClipCategory.text);
    final pinned = await repo.create(name: 'Pinned', content: 'y', category: ClipCategory.text);
    await repo.setPinned(pinned.id, true);
    final all = await repo.getAll();
    expect(all.first.id, pinned.id);
  });
}
