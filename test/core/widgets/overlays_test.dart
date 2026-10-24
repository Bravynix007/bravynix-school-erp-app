import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('showAppBottomSheet', () {
    testWidgets('shows the title and body, and the body can close it with a result', (tester) async {
      int? result;
      await tester.pumpApp(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: AppButton(
                label: 'Open',
                onPressed: () async {
                  result = await showAppBottomSheet<int>(
                    context: context,
                    title: 'Add a note',
                    builder: (sheet) => AppButton(label: 'Save', onPressed: () => Navigator.of(sheet).pop(7)),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Add a note'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, 7);
      expect(find.text('Add a note'), findsNothing);
    });

    testWidgets('a tall body scrolls inside the sheet at 200% text on a small phone', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 480)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 480), textScaler: TextScaler.linear(2)),
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showAppBottomSheet<void>(
                    context: context,
                    title: 'Details',
                    builder: (_) => Column(children: [for (var i = 0; i < 20; i += 1) Text('Row $i')]),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Details'), findsOneWidget);
    });
  });

  group('showConfirmDialog', () {
    Future<bool?> open(WidgetTester tester, {required String tap, bool destructive = false}) async {
      bool? result;
      await tester.pumpApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showConfirmDialog(
                  context: context,
                  title: 'Delete this class?',
                  message: 'Its students stay.',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  destructive: destructive,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      if (tap.isNotEmpty) {
        await tester.tap(find.text(tap));
        await tester.pumpAndSettle();
      }
      return result;
    }

    testWidgets('confirm gives true', (tester) async {
      expect(await open(tester, tap: 'Delete'), isTrue);
    });

    testWidgets('cancel gives false', (tester) async {
      expect(await open(tester, tap: 'Cancel'), isFalse);
    });

    testWidgets('shows the title and message, and a destructive confirm is red', (tester) async {
      await open(tester, destructive: true, tap: '');
      expect(find.text('Delete this class?'), findsOneWidget);
      expect(find.text('Its students stay.'), findsOneWidget);
      final material = find
          .descendant(of: find.widgetWithText(FilledButton, 'Delete'), matching: find.byType(Material))
          .first;
      expect(tester.widget<Material>(material).color, AppColors.error);
    });
  });

  group('StatePanel', () {
    testWidgets('shows title, message and an action that works', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Scaffold(
          body: StatePanel.error(
            title: 'Something went wrong',
            message: 'Try again.',
            actionLabel: 'Retry',
            onAction: () => taps += 1,
          ),
        ),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(taps, 1);
    });

    testWidgets('each preset has its own icon, and the action is optional', (tester) async {
      final presets = <(Widget, IconData)>[
        (const StatePanel.empty(title: 'None'), Icons.inbox_outlined),
        (const StatePanel.error(title: 'Error'), Icons.error_outline),
        (const StatePanel.offline(title: 'Offline'), Icons.wifi_off_outlined),
        (const StatePanel.forbidden(title: 'No access'), Icons.lock_outline),
        (const StatePanel.conflict(title: 'Changed'), Icons.sync_problem_outlined),
      ];
      for (final (panel, icon) in presets) {
        await tester.pumpApp(Scaffold(body: panel));
        expect(find.byIcon(icon), findsOneWidget);
        expect(find.byType(AppButton), findsNothing);
      }
    });

    testWidgets('scrolls instead of overflowing at 200% text on a small phone', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 400), textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: StatePanel.conflict(
                title: 'Someone else changed this',
                message: 'Reload to see the latest version, then make your change again.',
                actionLabel: 'Reload',
                onAction: () {},
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Skeleton', () {
    testWidgets('pulses, and keeps still when the phone removes animations', (tester) async {
      Color? colourOf() {
        final box = tester.widget<DecoratedBox>(
          find.descendant(of: find.byType(SkeletonBox), matching: find.byType(DecoratedBox)),
        );
        return (box.decoration as BoxDecoration).color;
      }

      await tester.pumpApp(const Scaffold(body: SkeletonBox(width: 100)));
      final start = colourOf();
      await tester.pump(const Duration(milliseconds: 450));
      expect(colourOf(), isNot(start));

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: SkeletonBox(width: 100)),
          ),
        ),
      );
      final still = colourOf();
      await tester.pump(const Duration(milliseconds: 450));
      expect(colourOf(), still);
      await tester.pumpAndSettle();
    });

    testWidgets('SkeletonList speaks one label for the whole list', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(const Scaffold(body: SkeletonList(semanticLabel: 'Loading students')));
      expect(find.bySemanticsLabel('Loading students'), findsOneWidget);
      handle.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
