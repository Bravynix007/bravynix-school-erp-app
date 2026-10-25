import 'package:bravynix_school_erp/core/a11y/reduce_motion.dart';
import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/module_header.dart';
import 'package:bravynix_school_erp/core/widgets/notification_bell.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/contrast.dart';
import '../../helpers/pump_app.dart';

Widget _moduleScreen() => Scaffold(
  body: CustomScrollView(
    slivers: [
      ModuleHeader(
        title: 'Attendance',
        heroIcon: Icons.event_available_outlined,
        heroTitle: 'Mark attendance',
        description: "Mark today's attendance for your section",
        onBack: () {},
        backTooltip: 'Back',
        actions: [NotificationBell(tooltip: 'Notifications', onPressed: () {}, onAccent: true)],
      ),
      SliverList.builder(itemCount: 30, itemBuilder: (_, i) => SizedBox(height: 60, child: Text('Row $i'))),
    ],
  ),
);

Future<void> _pumpAccent(WidgetTester tester, AppAccent accent, Widget home) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(accent: accent),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

/// The outline the button's own `Material` draws, i.e. its keyboard focus ring.
BorderSide _side(WidgetTester tester, Finder button) {
  final material = tester.widget<Material>(find.ancestor(of: button, matching: find.byType(Material)).first);
  return (material.shape! as OutlinedBorder).side;
}

/// The painted bar (its white Material), without the padding that lifts it above the keyboard.
Rect _barRect(WidgetTester tester) =>
    tester.getRect(find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(Material)).first);

SystemUiOverlayStyle _overlayOf(WidgetTester tester, Finder within) => tester
    .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find
          .descendant(
            of: within,
            matching: find.byWidgetPredicate((w) => w is AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .first,
    )
    .value;

void main() {
  group('StickyBottomActions and the keyboard', () {
    Widget screen() => Scaffold(
      body: const Padding(padding: EdgeInsets.all(16), child: TextField()),
      bottomNavigationBar: StickyBottomActions(
        primaryLabel: 'Save',
        onPrimary: () {},
        secondaryLabel: 'Cancel',
        onSecondary: () {},
      ),
    );

    testWidgets('stays above the keyboard and the body still ends above the bar', (tester) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAppScaled(screen());
      final save = tester.getRect(find.text('Save'));
      expect(save.bottom, lessThanOrEqualTo(640 - 300), reason: 'the keyboard covers the bottom 300 px');
      final bar = _barRect(tester);
      expect(bar.bottom, lessThanOrEqualTo(640 - 300));
      expect(tester.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(bar.top));
    });

    testWidgets('with no keyboard it sits at the bottom of the screen as before', (tester) async {
      await tester.pumpAppScaled(screen());
      expect(_barRect(tester).bottom, 640);
    });

    testWidgets('does not add the home indicator gap on top of the keyboard', (tester) async {
      tester.view
        ..viewInsets = const FakeViewPadding(bottom: 300)
        ..padding = const FakeViewPadding(bottom: 34);
      await tester.pumpAppScaled(screen(), bottomPadding: 34);
      expect(_barRect(tester).bottom, 640 - 300);
    });
  });

  group('ModuleHeader focus ring', () {
    for (final accent in [AppAccent.teal, AppAccent.forestGreen]) {
      testWidgets('on ${accent.name}: the back button and the bell get a white 2 px ring', (tester) async {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
        addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
        await _pumpAccent(tester, accent, _moduleScreen());
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final white = AppTheme.light(accent: accent).colorScheme.onPrimary;
        expect(_side(tester, find.byIcon(Icons.arrow_back)), BorderSide(color: white, width: 2));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_side(tester, find.byIcon(Icons.notifications_none)), BorderSide(color: white, width: 2));
        expect(contrast(white, accent.primary), greaterThanOrEqualTo(3));
      });
    }

    testWidgets('an unfocused button draws no outline', (tester) async {
      await tester.pumpApp(_moduleScreen());
      expect(_side(tester, find.byIcon(Icons.arrow_back)), BorderSide.none);
    });
  });

  group('Status bar style', () {
    testWidgets('AppTopBar asks for dark icons on a transparent bar, so going back from a module resets it', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(
          body: Column(children: [AppTopBar(title: 'Home')]),
        ),
      );
      final style = _overlayOf(tester, find.byType(AppTopBar));
      expect(style.statusBarIconBrightness, Brightness.dark);
      expect(style.statusBarColor, Colors.transparent);
    });

    testWidgets('ModuleHeader asks for light icons on a transparent bar', (tester) async {
      await tester.pumpApp(_moduleScreen());
      final style = _overlayOf(tester, find.byType(SliverPersistentHeader));
      expect(style.statusBarIconBrightness, Brightness.light);
      expect(style.statusBarColor, Colors.transparent);
    });
  });

  group('ModuleHeader hero while it fades', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('at ${scale * 100}% the hero never reaches the title row', (tester) async {
        await tester.pumpAppScaled(_moduleScreen(), textScale: scale);
        for (final offset in [0.0, 8.0, 20.0, 60.0]) {
          await tester.drag(find.byType(CustomScrollView), Offset(0, -offset));
          await tester.pump();
          final region = tester.getRect(
            find.descendant(of: find.byType(SliverPersistentHeader), matching: find.byType(ClipRect)).first,
          );
          final title = tester.getRect(find.text('Attendance'));
          expect(
            region.top,
            greaterThanOrEqualTo(title.bottom - 0.5),
            reason: 'the clipped hero region starts below the title ($offset px scrolled)',
          );
        }
      });
    }

    testWidgets('the title is read before the hero card', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(_moduleScreen());
      final labels = tester.semantics.simulatedAccessibilityTraversal().map((node) => node.label).toList();
      expect(
        labels.indexWhere((l) => l.contains('Attendance')),
        lessThan(labels.indexWhere((l) => l.contains('Mark attendance'))),
      );
      handle.dispose();
    });

    testWidgets('with no actions the title keeps a full screen margin from the edge', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: CustomScrollView(
            slivers: [
              ModuleHeader(
                title: 'Attendance',
                heroIcon: Icons.event_available_outlined,
                heroTitle: 'Mark attendance',
                onBack: () {},
                backTooltip: 'Back',
              ),
            ],
          ),
        ),
      );
      final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final titleRow = tester.getRect(find.text('Attendance'));
      expect(titleRow.right, lessThan(screenWidth - 16 + 0.5));
    });
  });

  group('reduceMotion', () {
    Future<bool> ask(WidgetTester tester) async {
      late bool result;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            result = reduceMotion(context);
            return const SizedBox();
          },
        ),
      );
      return result;
    }

    testWidgets('is off by default', (tester) async {
      expect(await ask(tester), isFalse);
    });

    testWidgets('is on for Android remove animations', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      expect(await ask(tester), isTrue);
    });

    testWidgets('is on for iOS Reduce Motion', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      expect(await ask(tester), isTrue);
    });
  });

  group('fitWordScaler', () {
    testWidgets('returns a scale at which the longest word really fits', (tester) async {
      late BuildContext captured;
      await tester.pumpAppScaled(
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
        textScale: 3,
      );
      final style = Theme.of(captured).textTheme.titleLarge;
      for (final word in ['Superintendent', 'Administration', 'Examinations']) {
        final scaler = fitWordScaler(captured, word, style, 200);
        expect(measureText(captured, word, style, scaler: scaler), lessThanOrEqualTo(200), reason: word);
      }
    });

    testWidgets('keeps the phone scale when the word already fits', (tester) async {
      late BuildContext captured;
      await tester.pumpAppScaled(
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      );
      final scaler = fitWordScaler(captured, 'Home', Theme.of(captured).textTheme.titleLarge, 200);
      expect(scaler, MediaQuery.textScalerOf(captured));
    });
  });
}
