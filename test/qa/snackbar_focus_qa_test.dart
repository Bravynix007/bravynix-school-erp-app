// QA for app PR 5 retest: where focus goes after a snackbar closes, for a touch
// user and when the action opens another page.
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

Widget _page({required void Function(BuildContext) onRetry}) => SnackbarEscape(
  child: Scaffold(
    body: Builder(
      builder: (context) => Column(
        children: [
          ElevatedButton(
            onPressed: () => AppSnackbar.show(
              context,
              message: 'Could not save. Try again.',
              kind: AppSnackbarKind.error,
              actionLabel: 'Retry',
              onAction: () => onRetry(context),
              dismissLabel: 'Dismiss',
            ),
            child: const Text('Save'),
          ),
          const TextField(decoration: InputDecoration(labelText: 'Note')),
        ],
      ),
    ),
  ),
);

bool _hasFocus(WidgetTester tester, String text) => Focus.of(tester.element(find.text(text))).hasPrimaryFocus;

void main() {
  tearDown(AppSnackbar.debugReset);

  testWidgets('touch: tapping Save then Dismiss moves no focus and opens no keyboard', (tester) async {
    await tester.pumpAppScaled(_page(onRetry: (_) {}), size: const Size(390, 844));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save. Try again.'), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
    final focus = FocusManager.instance.primaryFocus;
    expect(focus == null || focus is FocusScopeNode, isTrue, reason: 'focus is $focus');
  });

  testWidgets('touch after typing: Retry does not put focus back in the text field', (tester) async {
    await tester.pumpAppScaled(_page(onRetry: (_) {}), size: const Size(390, 844));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('keyboard: Retry that opens a page leaves focus in the new page', (tester) async {
    await tester.pumpAppScaled(
      _page(
        onRetry: (context) => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: ElevatedButton(onPressed: () {}, child: const Text('On the new page')),
            ),
          ),
        ),
      ),
      size: const Size(390, 844),
    );
    Focus.of(tester.element(find.text('Save'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.text('Retry'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('On the new page'), findsOneWidget);
    final ctx = FocusManager.instance.primaryFocus?.context;
    expect(ctx == null ? null : ModalRoute.of(ctx)?.isCurrent, isTrue, reason: 'focus is on the new page');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_hasFocus(tester, 'On the new page'), isTrue, reason: 'Tab moves within the new page');
  });

  testWidgets('keyboard: two messages in a row still return focus to Save', (tester) async {
    await tester.pumpAppScaled(_page(onRetry: (_) {}), size: const Size(390, 844));
    Focus.of(tester.element(find.text('Save'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter); // Save again: the message is replaced
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.text('Dismiss'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_hasFocus(tester, 'Save'), isTrue);
  });
}
