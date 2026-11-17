import 'package:bravynix_school_erp/core/widgets/switcher_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  const options = ['a', 'b', 'c'];

  Widget card({List<String> shown = options, String selected = 'b', ValueChanged<String>? onSelected}) => Scaffold(
    body: SwitcherCard<String>(
      options: shown,
      selected: selected,
      idOf: (option) => option,
      titleOf: (option) => 'Option $option',
      hint: 'Change',
      sheetTitle: 'Pick one',
      optionKeyPrefix: 'switch.option',
      onSelected: onSelected ?? (_) {},
    ),
  );

  testWidgets('the open sheet marks the selected option and no other', (tester) async {
    await tester.pumpApp(card());
    await tester.tap(find.text('Option b'));
    await tester.pumpAndSettle();
    Finder mark(String id, IconData icon) =>
        find.descendant(of: find.byKey(ValueKey('switch.option.$id')), matching: find.byIcon(icon));
    expect(mark('b', Icons.radio_button_checked), findsOneWidget);
    expect(mark('a', Icons.radio_button_unchecked), findsOneWidget);
    expect(mark('c', Icons.radio_button_unchecked), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
  });

  testWidgets('picking another option reports it, and picking the current one does not', (tester) async {
    final picked = <String>[];
    await tester.pumpApp(card(onSelected: picked.add));
    await tester.tap(find.text('Option b'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('switch.option.b')));
    await tester.pumpAndSettle();
    expect(picked, isEmpty);
    await tester.tap(find.text('Option b'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('switch.option.c')));
    await tester.pumpAndSettle();
    expect(picked, ['c']);
  });

  testWidgets('with one option the card only names it, with no hint to tap', (tester) async {
    await tester.pumpApp(card(shown: const ['b']));
    expect(find.text('Option b'), findsOneWidget);
    expect(find.text('Change'), findsNothing);
  });
}
