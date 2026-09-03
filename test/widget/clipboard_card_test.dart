import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cliphold/models/clip_item.dart';
import 'package:cliphold/models/enums.dart';
import 'package:cliphold/widgets/clipboard_card.dart';

ClipItem _sampleItem({bool pinned = false, int copyCount = 1}) {
  final now = DateTime.now();
  return ClipItem(
    id: '1',
    content: 'Hello from a test clip',
    category: ClipCategory.text,
    createdAt: now,
    updatedAt: now,
    pinned: pinned,
    contentHash: 'hash1',
    copyCount: copyCount,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders content preview and category label', (tester) async {
    await tester.pumpWidget(_wrap(ClipboardCard(
      item: _sampleItem(),
      onCopy: () {},
      onPin: () {},
      onDelete: () {},
      onEdit: () {},
    )));

    expect(find.text('Hello from a test clip'), findsOneWidget);
    expect(find.text('Text'), findsOneWidget);
  });

  testWidgets('shows pin icon and copy count badge when applicable', (tester) async {
    await tester.pumpWidget(_wrap(ClipboardCard(
      item: _sampleItem(pinned: true, copyCount: 4),
      onCopy: () {},
      onPin: () {},
      onDelete: () {},
      onEdit: () {},
    )));

    expect(find.text('×4'), findsOneWidget);
    // Two pin icons expected: header indicator + pin action button (filled).
    expect(find.byIcon(Icons.push_pin_rounded), findsWidgets);
  });

  testWidgets('tapping copy button triggers onCopy', (tester) async {
    var copied = false;
    await tester.pumpWidget(_wrap(ClipboardCard(
      item: _sampleItem(),
      onCopy: () => copied = true,
      onPin: () {},
      onDelete: () {},
      onEdit: () {},
    )));

    await tester.tap(find.byIcon(Icons.copy_rounded));
    await tester.pump();
    expect(copied, true);
  });

  testWidgets('tapping pin button triggers onPin', (tester) async {
    var pinned = false;
    await tester.pumpWidget(_wrap(ClipboardCard(
      item: _sampleItem(),
      onCopy: () {},
      onPin: () => pinned = true,
      onDelete: () {},
      onEdit: () {},
    )));

    await tester.tap(find.byIcon(Icons.push_pin_outlined));
    await tester.pump();
    expect(pinned, true);
  });

  testWidgets('tapping delete button triggers onDelete', (tester) async {
    var deleted = false;
    await tester.pumpWidget(_wrap(ClipboardCard(
      item: _sampleItem(),
      onCopy: () {},
      onPin: () {},
      onDelete: () => deleted = true,
      onEdit: () {},
    )));

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump();
    expect(deleted, true);
  });
}
