import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cliphold/providers/app_state.dart';
import 'package:cliphold/repositories/clipboard_repository.dart';
import 'package:cliphold/repositories/snippet_repository.dart';
import 'package:cliphold/screens/history_screen.dart';
import 'package:cliphold/services/database_service.dart';

/// A minimal AppState subclass that skips window/tray/hotkey/clipboard OS
/// integration (not available in the widget-test environment) while still
/// exercising real repository-backed data loading and UI states.
class _TestAppState extends AppState {
  _TestAppState(ClipboardRepository clipRepo, SnippetRepository snipRepo)
      : super(clipboardRepository: clipRepo, snippetRepository: snipRepo);

  Future<void> initForTest() async {
    isLoading = false;
    await refreshClips();
    await refreshSnippets();
  }
}

Future<DatabaseService> _newInMemoryDb() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await DatabaseService.createSchema(db);
  return DatabaseService.forTesting(db);
}

Widget _wrapWithState(AppState state, Widget child) {
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows empty state when there are no clips', (tester) async {
    final db = await _newInMemoryDb();
    final state = _TestAppState(ClipboardRepository(db: db), SnippetRepository(db: db));
    await state.initForTest();

    await tester.pumpWidget(_wrapWithState(state, const HistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No clips yet'), findsOneWidget);
  });

  testWidgets('renders captured clips as cards', (tester) async {
    final db = await _newInMemoryDb();
    final clipRepo = ClipboardRepository(db: db);
    await clipRepo.captureClip('First test clip');
    await clipRepo.captureClip('Second test clip');

    final state = _TestAppState(clipRepo, SnippetRepository(db: db));
    await state.initForTest();

    await tester.pumpWidget(_wrapWithState(state, const HistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('First test clip'), findsOneWidget);
    expect(find.textContaining('Second test clip'), findsOneWidget);
    expect(find.text('No clips yet'), findsNothing);
  });

  testWidgets('pin action calls through to repository', (tester) async {
    final db = await _newInMemoryDb();
    final clipRepo = ClipboardRepository(db: db);
    final item = await clipRepo.captureClip('Pin candidate');

    final state = _TestAppState(clipRepo, SnippetRepository(db: db));
    await state.initForTest();

    await tester.pumpWidget(_wrapWithState(state, const HistoryScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.push_pin_outlined));
    await tester.pumpAndSettle();

    final refreshed = await clipRepo.getAll(pinnedOnly: true);
    expect(refreshed.length, 1);
    expect(refreshed.first.id, item!.id);
  });

  testWidgets('deleting a clip removes its card from the list', (tester) async {
    final db = await _newInMemoryDb();
    final clipRepo = ClipboardRepository(db: db);
    await clipRepo.captureClip('Delete candidate');

    final state = _TestAppState(clipRepo, SnippetRepository(db: db));
    await state.initForTest();

    await tester.pumpWidget(_wrapWithState(state, const HistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Delete candidate'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('Delete candidate'), findsNothing);
    expect(find.text('No clips yet'), findsOneWidget);
  });

  testWidgets('typing in the search bar filters visible clips', (tester) async {
    final db = await _newInMemoryDb();
    final clipRepo = ClipboardRepository(db: db);
    await clipRepo.captureClip('apple banana');
    await clipRepo.captureClip('completely different');

    final state = _TestAppState(clipRepo, SnippetRepository(db: db));
    await state.initForTest();

    await tester.pumpWidget(_wrapWithState(state, const HistoryScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'banana');
    await tester.pumpAndSettle();

    expect(find.textContaining('apple banana'), findsOneWidget);
    expect(find.textContaining('completely different'), findsNothing);
  });
}
