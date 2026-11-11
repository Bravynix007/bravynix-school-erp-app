import 'package:bravynix_school_erp/core/widgets/optional_date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  final first = DateTime(1990);
  final last = DateTime(2030, 12, 31);
  late List<String?> chosen;

  setUp(() => chosen = []);

  Future<void> pump(
    WidgetTester tester, {
    String? day,
    DateTime? initialDay,
    DateTime? firstDay,
    double textScale = 1,
  }) => tester.pumpAppScaled(
    Scaffold(
      body: OptionalDateField(
        label: 'Joining date',
        day: day,
        hint: 'Choose a date',
        clearLabel: 'Clear Joining date',
        firstDay: firstDay ?? first,
        lastDay: last,
        initialDay: initialDay,
        onChanged: chosen.add,
      ),
    ),
    textScale: textScale,
    size: const Size(400, 800),
  );

  /// Opens the calendar from the field's own text, the day or the hint, and accepts the day it opens on.
  Future<void> pickWithOk(WidgetTester tester) async {
    await tester.tap(find.descendant(of: find.byType(OptionalDateField), matching: find.byType(GestureDetector)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the hint when no day is set, with no clear button', (tester) async {
    await pump(tester);
    expect(find.text('Choose a date'), findsOneWidget);
    expect(find.byTooltip('Clear Joining date'), findsNothing);
  });

  testWidgets('shows the day set as DD-MM-YYYY, with a clear button that sends null', (tester) async {
    await pump(tester, day: '2020-06-01');
    expect(find.text('01-06-2020'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear Joining date'));
    expect(chosen, [null]);
  });

  testWidgets('opens on the day set and sends the day picked as YYYY-MM-DD', (tester) async {
    await pump(tester, day: '2020-06-01');
    await pickWithOk(tester);
    expect(chosen, ['2020-06-01']);
  });

  testWidgets('opens on the initial day when none is set', (tester) async {
    await pump(tester, initialDay: DateTime(2000, 3, 9));
    await pickWithOk(tester);
    expect(chosen, ['2000-03-09']);
  });

  testWidgets('sends nothing when the calendar is dismissed', (tester) async {
    await pump(tester, day: '2020-06-01');
    await tester.tap(find.descendant(of: find.byType(OptionalDateField), matching: find.byType(GestureDetector)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(chosen, isEmpty);
  });

  testWidgets('opens inside the allowed days when the day set or today lies outside them', (tester) async {
    await pump(tester, day: '1950-01-01');
    await pickWithOk(tester);
    expect(chosen, ['1990-01-01']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reads whole at a large text scale', (tester) async {
    await pump(tester, day: '2020-06-01', textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Clear Joining date'), findsOneWidget);
  });
}
