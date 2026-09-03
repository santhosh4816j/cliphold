import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cliphold/models/enums.dart';
import 'package:cliphold/widgets/category_filter.dart';
import 'package:cliphold/widgets/search_bar.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AppSearchBar', () {
    testWidgets('calls onChanged as text is typed', (tester) async {
      String? lastValue;
      await tester.pumpWidget(_wrap(AppSearchBar(onChanged: (v) => lastValue = v)));

      await tester.enterText(find.byType(TextField), 'hello');
      expect(lastValue, 'hello');
    });

    testWidgets('shows clear button only when there is text', (tester) async {
      await tester.pumpWidget(_wrap(AppSearchBar(onChanged: (_) {})));
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('clear button empties the field and calls onChanged with empty string',
        (tester) async {
      String? lastValue;
      await tester.pumpWidget(_wrap(AppSearchBar(onChanged: (v) => lastValue = v)));
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(lastValue, '');
      expect(find.text('abc'), findsNothing);
    });
  });

  group('CategoryFilterBar', () {
    testWidgets('renders All plus every category', (tester) async {
      await tester.pumpWidget(_wrap(CategoryFilterBar(
        selected: null,
        onSelected: (_) {},
      )));

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Links'), findsOneWidget);
      expect(find.text('Code'), findsOneWidget);
    });

    testWidgets('tapping a category chip invokes onSelected with that category',
        (tester) async {
      ClipCategory? selected;
      bool selectedNullCalled = false;
      await tester.pumpWidget(_wrap(CategoryFilterBar(
        selected: null,
        onSelected: (c) {
          selected = c;
          if (c == null) selectedNullCalled = true;
        },
      )));

      await tester.tap(find.text('Code'));
      await tester.pump();
      expect(selected, ClipCategory.code);
      expect(selectedNullCalled, false);
    });
  });
}
