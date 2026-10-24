import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

final Finder _dragHandle = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_DragHandle');

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

    Future<void> openSheet(
      WidgetTester tester, {
      bool isDismissible = true,
      double scale = 1,
      double bottomPadding = 0,
    }) async {
      await tester.pumpAppScaled(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppBottomSheet<void>(
                context: context,
                title: 'Details',
                isDismissible: isDismissible,
                builder: (_) => Column(
                  children: [
                    for (var i = 0; i < 12; i += 1) Text('Row $i'),
                    AppButton(label: 'Save', onPressed: () {}),
                  ],
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
        textScale: scale,
        size: const Size(320, 480),
        bottomPadding: bottomPadding,
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('at 200% text the sheet itself is drawn at 200% and its body scrolls', (tester) async {
      await openSheet(tester);
      final normal = tester.textHeight('Details');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await openSheet(tester, scale: 2);
      expect(tester.takeException(), isNull);
      expect(tester.textHeight('Details'), greaterThan(normal * 1.9), reason: 'the scale reaches the sheet');
      final scrollable = find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable));
      expect(scrollable, findsOneWidget);
      await tester.scrollUntilVisible(find.text('Save'), 100, scrollable: scrollable);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('keeps the last button clear of the home indicator', (tester) async {
      await openSheet(tester, bottomPadding: 34);
      final scrollable = find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable));
      await tester.scrollUntilVisible(find.text('Save'), 100, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(FilledButton)).bottom, lessThanOrEqualTo(480 - 34));
    });

    testWidgets('a sheet that is not dismissible has no drag handle and ignores back and the barrier', (tester) async {
      await openSheet(tester, isDismissible: false);
      expect(_dragHandle, findsNothing);
      await tester.tapAt(const Offset(160, 10));
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('a dismissible sheet has a drag handle and closes on back', (tester) async {
      await openSheet(tester);
      expect(_dragHandle, findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsNothing);
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

    testWidgets('an icon is drawn in a 64 px tinted circle, and the body scrolls at 200% text', (tester) async {
      await tester.pumpAppScaled(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showConfirmDialog(
                context: context,
                title: 'Delete this class and everything in it?',
                message:
                    'Its students stay, but they will have no class, and the timetable for the class is removed too.',
                confirmLabel: 'Delete',
                cancelLabel: 'Cancel',
                destructive: true,
                icon: Icons.delete_outline,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
        textScale: 2,
        size: const Size(320, 400),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final circle = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      expect(tester.getSize(circle), const Size.square(64));
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.byType(SingleChildScrollView)), findsWidgets);
      expect(tester.textHeight('Cancel'), greaterThan(30), reason: 'buttons are drawn at 200%');
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

    testWidgets('errors and offline are announced when they appear; empty is not', (tester) async {
      final handle = tester.ensureSemantics();
      for (final (panel, live) in <(Widget, bool)>[
        (const StatePanel.error(title: 'Failed'), true),
        (const StatePanel.offline(title: 'Offline'), true),
        (const StatePanel.empty(title: 'Nothing'), false),
        (const StatePanel.forbidden(title: 'No access'), false),
      ]) {
        await tester.pumpApp(Scaffold(body: panel));
        final label = (panel as StatePanel).title;
        expect(
          tester.getSemantics(find.bySemanticsLabel(RegExp(label))).flagsCollection.isLiveRegion,
          live ? isTrue : isFalse,
          reason: label,
        );
      }
      handle.dispose();
    });

    testWidgets('scrolls instead of overflowing at 200% text on a small phone, with the text drawn at 200%', (
      tester,
    ) async {
      Future<void> pump(double scale) => tester.pumpAppScaled(
        StatePanel.conflict(
          title: 'Someone else changed this',
          message: 'Reload to see the latest version, then make your change again.',
          actionLabel: 'Reload',
          onAction: () {},
        ),
        textScale: scale,
        size: const Size(320, 400),
      );
      await pump(1);
      final normal = tester.textHeight('Someone else changed this');
      await pump(2);
      expect(tester.takeException(), isNull);
      expect(tester.textHeight('Someone else changed this'), greaterThan(normal * 1.9));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
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

    testWidgets('keeps still when the phone says reduce motion (iOS)', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pumpApp(const Scaffold(body: SkeletonBox(width: 100)));
      final box = find.descendant(of: find.byType(SkeletonBox), matching: find.byType(DecoratedBox));
      final still = (tester.widget<DecoratedBox>(box).decoration as BoxDecoration).color;
      await tester.pump(const Duration(milliseconds: 450));
      expect((tester.widget<DecoratedBox>(box).decoration as BoxDecoration).color, still);
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
