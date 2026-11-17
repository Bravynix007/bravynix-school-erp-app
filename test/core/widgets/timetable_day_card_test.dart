import 'package:bravynix_school_erp/core/widgets/timetable_day_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  Widget card({bool open = false}) => Scaffold(
    body: TimetableDayCard(title: 'Monday', summary: '3 periods', initiallyOpen: open, child: const Text('Periods')),
  );

  testWidgets('shows the day and its summary, and the periods only once it is open', (tester) async {
    await tester.pumpApp(card());
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('3 periods'), findsOneWidget);
    expect(find.text('Periods'), findsNothing);
    await tester.tap(find.text('Monday'));
    await tester.pump();
    expect(find.text('Periods'), findsOneWidget);
    await tester.tap(find.text('Monday'));
    await tester.pump();
    expect(find.text('Periods'), findsNothing);
  });

  testWidgets('starts open when asked to', (tester) async {
    await tester.pumpApp(card(open: true));
    expect(find.text('Periods'), findsOneWidget);
  });

  testWidgets('is one button that says whether it is expanded', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(card());
    final label = find.bySemanticsLabel('Monday, 3 periods');
    expect(
      tester.getSemantics(label),
      matchesSemantics(
        label: 'Monday, 3 periods',
        isButton: true,
        hasTapAction: true,
        hasExpandedState: true,
      ),
    );
    await tester.tap(find.text('Monday'));
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Monday, 3 periods')),
      matchesSemantics(
        label: 'Monday, 3 periods',
        isButton: true,
        hasTapAction: true,
        isExpanded: true,
        hasExpandedState: true,
      ),
    );
    handle.dispose();
  });
}
