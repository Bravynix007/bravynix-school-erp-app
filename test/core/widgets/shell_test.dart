import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_fab.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/floating_pill_nav_bar.dart';
import 'package:bravynix_school_erp/core/widgets/module_header.dart';
import 'package:bravynix_school_erp/core/widgets/notification_bell.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/contrast.dart';
import '../../helpers/pump_app.dart';

const _items = [
  PillNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
  PillNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
];

const _fiveItems = [
  PillNavItem(icon: Icons.home_outlined, label: 'Home'),
  PillNavItem(icon: Icons.event_available_outlined, label: 'Attendance'),
  PillNavItem(icon: Icons.school_outlined, label: 'Students'),
  PillNavItem(icon: Icons.payments_outlined, label: 'Fees'),
  PillNavItem(icon: Icons.person_outline, label: 'Profile'),
];

Future<void> _pumpAccent(WidgetTester tester, AppAccent accent, Widget home) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(accent: accent),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  group('NotificationBell', () {
    Future<void> pump(WidgetTester tester, int count) => tester.pumpApp(
      Scaffold(
        body: NotificationBell(tooltip: 'Notifications', unreadLabel: '$count unread', count: count, onPressed: () {}),
      ),
    );

    testWidgets('shows the count, and 9+ above nine, and nothing at zero', (tester) async {
      await pump(tester, 3);
      expect(find.text('3'), findsOneWidget);
      await pump(tester, 9);
      expect(find.text('9'), findsOneWidget);
      await pump(tester, 10);
      expect(find.text('9+'), findsOneWidget);
      await pump(tester, 0);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('speaks its name and the unread count as one button', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, 3);
      // The IconButton carries the name, so the node stays focusable for a screen reader (QA D2).
      expect(
        tester.getSemantics(find.byType(IconButton)),
        isSemantics(
          label: 'Notifications, 3 unread',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(find.bySemanticsLabel('3'), findsNothing, reason: 'the badge is not read on its own');
      await pump(tester, 0);
      expect(
        tester.getSemantics(find.byType(IconButton)),
        isSemantics(
          label: 'Notifications',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the badge is white on red and the touch target is 48 px', (tester) async {
      await pump(tester, 3);
      expect(contrast(Colors.white, AppColors.error), greaterThanOrEqualTo(4.5));
      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('AppTopBar', () {
    testWidgets('shows the label, the title and the actions, and is 64 px tall', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: Column(
            children: [
              AppTopBar(
                overline: 'Good afternoon',
                title: 'Kavya',
                leading: const SizedBox.square(dimension: 40),
                actions: [NotificationBell(tooltip: 'Notifications', onPressed: () {})],
              ),
            ],
          ),
        ),
      );
      expect(find.text('Good afternoon'), findsOneWidget);
      expect(find.text('Kavya'), findsOneWidget);
      expect(tester.getSize(find.byType(AppTopBar)).height, 64);
    });

    testWidgets('the back variant has a named back button that reports the tap', (tester) async {
      var backs = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        Scaffold(
          body: Column(
            children: [AppTopBar(title: 'Fee receipt', onBack: () => backs += 1, backTooltip: 'Back')],
          ),
        ),
      );
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(
        tester.getSemantics(find.byTooltip('Back')),
        isSemantics(tooltip: 'Back', isButton: true, hasTapAction: true),
      );
      await tester.tap(find.byTooltip('Back'));
      expect(backs, 1);
      expect(tester.getSize(find.byTooltip('Back')).width, greaterThanOrEqualTo(48));
      handle.dispose();
    });

    testWidgets('the title is a heading', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const Scaffold(
          body: Column(children: [AppTopBar(title: 'Fee receipt')]),
        ),
      );
      expect(
        tester.getSemantics(find.text('Fee receipt')),
        isSemantics(label: 'Fee receipt', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('at 300% text a long title wraps and the bar grows instead of cutting it', (tester) async {
      await tester.pumpAppScaled(
        const Scaffold(
          body: Column(
            children: [AppTopBar(overline: 'Good afternoon', title: 'Kavya Iyer-Subramaniam')],
          ),
        ),
        textScale: 3,
      );
      expect(tester.takeException(), isNull);
      final title = tester.renderObject<RenderParagraph>(find.text('Kavya Iyer-Subramaniam'));
      final needed = title.getDryLayout(BoxConstraints(maxWidth: title.size.width)).height;
      expect(title.size.height, greaterThanOrEqualTo(needed - 0.5));
      expect(tester.getSize(find.byType(AppTopBar)).height, greaterThan(64));
    });
  });

  group('ModuleHeader', () {
    Widget screen({String title = 'Attendance', String? description = "Mark today's attendance for your section"}) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            ModuleHeader(
              title: title,
              heroIcon: Icons.event_available_outlined,
              heroTitle: 'Mark attendance',
              description: description,
              onBack: () {},
              backTooltip: 'Back',
              actions: [NotificationBell(tooltip: 'Notifications', onPressed: () {}, onAccent: true)],
            ),
            SliverList.builder(itemCount: 30, itemBuilder: (_, i) => SizedBox(height: 60, child: Text('Row $i'))),
          ],
        ),
      );
    }

    Finder headerBox() =>
        find.descendant(of: find.byType(SliverPersistentHeader), matching: find.byType(ColoredBox)).first;

    testWidgets('is 260 px, accent coloured, with a back button, the title and the hero card', (tester) async {
      await tester.pumpApp(screen());
      expect(tester.getSize(headerBox()).height, ModuleHeader.expandedHeight);
      expect(tester.widget<ColoredBox>(headerBox()).color, AppAccent.teal.primary);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Mark attendance'), findsOneWidget);
      expect(find.text("Mark today's attendance for your section"), findsOneWidget);
    });

    testWidgets('on scrolling it pins to the back button and the title, and the hero card fades out', (tester) async {
      await tester.pumpApp(screen());
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();
      expect(tester.getSize(headerBox()).height, ModuleHeader.toolbarHeight);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
      final hero = find.ancestor(of: find.text('Mark attendance'), matching: find.byType(Opacity));
      expect(tester.widget<Opacity>(hero.first).opacity, 0);
    });

    testWidgets('the title is a heading and the back button is named', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(screen());
      expect(tester.getSemantics(find.text('Attendance')), isSemantics(label: 'Attendance', isHeader: true));
      expect(
        tester.getSemantics(find.byTooltip('Back')),
        isSemantics(tooltip: 'Back', isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    for (final accent in AppAccent.values) {
      testWidgets('${accent.label}: white text is readable on the header and on the hero card', (tester) async {
        await _pumpAccent(tester, accent, screen());
        expect(tester.widget<ColoredBox>(headerBox()).color, accent.primary);
        expect(contrast(Colors.white, accent.primary), greaterThanOrEqualTo(4.5));
        expect(contrast(Colors.white, accent.raised), greaterThanOrEqualTo(4.5));
        final hero = tester.widget<DecoratedBox>(
          find.ancestor(of: find.text('Mark attendance'), matching: find.byType(DecoratedBox)).first,
        );
        expect((hero.decoration as BoxDecoration).color, accent.raised);
      });
    }

    for (final scale in [1.3, 2.0, 3.0]) {
      testWidgets('at ${scale * 100}% text on a 320 px phone nothing is cut and the header grows', (tester) async {
        await tester.pumpAppScaled(
          screen(title: 'Attendance and diary'),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        for (final text in ['Attendance and diary', 'Mark attendance', "Mark today's attendance for your section"]) {
          final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
          final needed = paragraph.getDryLayout(BoxConstraints(maxWidth: paragraph.size.width)).height;
          expect(paragraph.size.height, greaterThanOrEqualTo(needed - 0.5), reason: '"$text" is not cut off');
          expect(paragraph.didExceedMaxLines, isFalse);
        }
        final card = tester.getRect(
          find.ancestor(of: find.text('Mark attendance'), matching: find.byType(DecoratedBox)).first,
        );
        final header = tester.getRect(headerBox());
        expect(card.bottom, lessThan(header.bottom), reason: 'the hero card sits inside the header');
        expect(header.height, greaterThanOrEqualTo(ModuleHeader.expandedHeight));
      });
    }

    testWidgets('without a back handler there is no back button, and without a description the card is shorter', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(
          body: CustomScrollView(
            slivers: [ModuleHeader(title: 'Home', heroIcon: Icons.home_outlined, heroTitle: 'Welcome')],
          ),
        ),
      );
      expect(find.byType(IconButton), findsNothing);
      expect(find.text('Welcome'), findsOneWidget);
    });
  });

  group('FloatingPillNavBar', () {
    Future<void> pump(
      WidgetTester tester, {
      List<PillNavItem> items = _items,
      int current = 0,
      ValueChanged<int>? onSelected,
      AppAccent accent = AppAccent.teal,
    }) => _pumpAccent(
      tester,
      accent,
      Scaffold(
        bottomNavigationBar: FloatingPillNavBar(items: items, currentIndex: current, onSelected: onSelected ?? (_) {}),
      ),
    );

    testWidgets('is a 64 px accent pill with radius 26, and the chosen tab is a white pill with its label', (
      tester,
    ) async {
      await pump(tester);
      final bar = tester.widget<DecoratedBox>(
        find.ancestor(of: find.byIcon(Icons.home), matching: find.byType(DecoratedBox)).last,
      );
      final decoration = bar.decoration as BoxDecoration;
      expect(decoration.color, AppAccent.teal.primary);
      expect(decoration.borderRadius, BorderRadius.circular(26));
      expect(tester.getSize(find.byType(FloatingPillNavBar)).height, greaterThanOrEqualTo(64));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsNothing, reason: 'only the chosen tab shows its label');
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      final pill = tester.widget<Material>(find.ancestor(of: find.text('Home'), matching: find.byType(Material)).first);
      expect(pill.color, AppColors.surface);
    });

    testWidgets('tapping another tab reports its index, and the bar follows the chosen one', (tester) async {
      var current = 0;
      late StateSetter setState;
      await _pumpAccent(
        tester,
        AppAccent.teal,
        Scaffold(
          bottomNavigationBar: StatefulBuilder(
            builder: (context, set) {
              setState = set;
              return FloatingPillNavBar(
                items: _items,
                currentIndex: current,
                onSelected: (i) => setState(() => current = i),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(current, 1);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('each tab is a named, selected-or-not tab in a group, 48 px at least', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, items: _fiveItems, current: 1);
      expect(
        tester.getSemantics(find.text('Attendance')),
        isSemantics(
          label: 'Attendance',
          hint: 'Tab 2 of 5',
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      expect(
        tester.getSemantics(find.byIcon(Icons.school_outlined)),
        isSemantics(
          label: 'Students',
          hint: 'Tab 3 of 5',
          isSelected: false,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    for (final accent in AppAccent.values) {
      testWidgets('${accent.label}: icons are readable on the accent and the chosen label on white', (tester) async {
        await pump(tester, accent: accent);
        expect(contrast(Colors.white, accent.primary), greaterThanOrEqualTo(4.5), reason: 'icons on the bar');
        expect(contrast(accent.text, AppColors.surface), greaterThanOrEqualTo(4.5), reason: 'label on the white pill');
        final label = tester.widget<Text>(find.text('Home'));
        expect(label.style?.color, accent.text);
      });
    }

    testWidgets('keyboard focus rings the tab: white on an icon tab, ink on the chosen pill', (tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
      await pump(tester);
      Iterable<Color> ringColours() => tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.border is Border && (d.border! as Border).top.width == 2)
          .map((d) => (d.border! as Border).top.color);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringColours(), [AppColors.focusRing], reason: 'the chosen pill is first in the tab order');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringColours(), [Colors.white]);
      expect(contrast(Colors.white, AppAccent.teal.primary), greaterThanOrEqualTo(3));
    });

    for (final scale in [1.0, 1.3, 2.0, 3.0]) {
      testWidgets('at ${scale * 100}% text with five tabs on 320 px nothing is cut or breaks a word', (tester) async {
        await tester.pumpAppScaled(
          const Scaffold(
            bottomNavigationBar: FloatingPillNavBar(items: _fiveItems, currentIndex: 1, onSelected: _ignore),
          ),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        final label = find.text('Attendance');
        if (label.evaluate().isNotEmpty) {
          final text = tester.renderObject<RenderParagraph>(label);
          final needed = text.getDryLayout(BoxConstraints(maxWidth: text.size.width)).height;
          expect(text.size.height, greaterThanOrEqualTo(needed - 0.5), reason: 'the label is not cut off');
          expect(text.size.height, lessThan(tester.textHeight('Attendance') + 1), reason: 'one line, no broken word');
        }
        final bar = tester.getRect(find.byType(FloatingPillNavBar));
        for (final icon in [
          Icons.home_outlined,
          Icons.school_outlined,
          Icons.payments_outlined,
          Icons.person_outline,
        ]) {
          final rect = tester.getRect(find.byIcon(icon));
          expect(rect.left, greaterThanOrEqualTo(bar.left));
          expect(rect.right, lessThanOrEqualTo(bar.right));
        }
      });
    }

    testWidgets('when the chosen label cannot fit beside the icon the pill keeps the icon and the name is spoken', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpAppScaled(
        const Scaffold(
          bottomNavigationBar: FloatingPillNavBar(items: _fiveItems, currentIndex: 1, onSelected: _ignore),
        ),
        textScale: 3,
      );
      expect(find.text('Attendance'), findsNothing);
      expect(
        tester.getSemantics(find.byIcon(Icons.event_available_outlined)),
        isSemantics(label: 'Attendance', hint: 'Tab 2 of 5', isSelected: true),
      );
      expect(find.byTooltip('Attendance'), findsOneWidget, reason: 'long-press shows the name');
      handle.dispose();
    });

    testWidgets('three tabs on a 320 px phone at the default size show the chosen label', (tester) async {
      await tester.pumpAppScaled(
        const Scaffold(
          bottomNavigationBar: FloatingPillNavBar(
            items: [
              ..._items,
              PillNavItem(icon: Icons.settings, label: 'Settings'),
            ],
            currentIndex: 0,
            onSelected: _ignore,
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('with reduced motion the switch is immediate', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      var current = 0;
      late StateSetter setState;
      await _pumpAccent(
        tester,
        AppAccent.teal,
        Scaffold(
          bottomNavigationBar: StatefulBuilder(
            builder: (context, set) {
              setState = set;
              return FloatingPillNavBar(
                items: _items,
                currentIndex: current,
                onSelected: (i) => setState(() => current = i),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pump();
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byType(AnimatedSize), findsNothing);
      expect(
        tester.getSize(find.ancestor(of: find.text('Profile'), matching: find.byType(Material)).first).width,
        greaterThan(100),
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('has two to five tabs', (tester) async {
      await tester.pumpApp(
        Scaffold(
          bottomNavigationBar: FloatingPillNavBar(items: _items.take(1).toList(), currentIndex: 0, onSelected: _ignore),
        ),
      );
      expect(tester.takeException(), isAssertionError);
      await tester.pumpApp(
        Scaffold(
          bottomNavigationBar: FloatingPillNavBar(
            items: [..._fiveItems, _fiveItems.first],
            currentIndex: 0,
            onSelected: _ignore,
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });

  group('AppFab', () {
    testWidgets('is an accent pill with an icon and a label, 56 px tall, that reports the tap', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Scaffold(
          floatingActionButton: AppFab(icon: Icons.add, label: 'Add student', onPressed: () => taps += 1),
        ),
      );
      expect(find.text('Add student'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(tester.getSize(find.byType(AppFab)).height, 56);
      final fill = tester.widget<Material>(
        find.ancestor(of: find.text('Add student'), matching: find.byType(Material)).first,
      );
      expect(fill.color, AppAccent.teal.primary);
      await tester.tap(find.text('Add student'));
      expect(taps, 1);
    });

    testWidgets('speaks as a button with its label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        Scaffold(
          floatingActionButton: AppFab(icon: Icons.add, label: 'Add student', onPressed: () {}),
        ),
      );
      expect(
        tester.getSemantics(find.text('Add student')),
        isSemantics(label: 'Add student', isButton: true, hasTapAction: true, isFocusable: true),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    for (final accent in AppAccent.values) {
      testWidgets('${accent.label}: white label and ring are readable on the pill', (tester) async {
        await _pumpAccent(
          tester,
          accent,
          Scaffold(
            floatingActionButton: AppFab(icon: Icons.add, label: 'Add', onPressed: () {}),
          ),
        );
        expect(contrast(Colors.white, accent.primary), greaterThanOrEqualTo(4.5));
        final label = tester.widget<Text>(find.text('Add'));
        expect(label.style?.color, Colors.white);
      });
    }

    testWidgets('at 300% text the label no longer fits, so it is the icon alone and the label is its name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpAppScaled(
        Scaffold(
          floatingActionButton: AppFab(icon: Icons.add, label: 'Add institution', onPressed: () {}),
        ),
        textScale: 3,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Add institution'), findsNothing);
      expect(tester.getSize(find.byType(AppFab)), const Size(56, 56));
      expect(
        tester.getSemantics(find.byIcon(Icons.add)),
        isSemantics(label: 'Add institution', isButton: true, hasTapAction: true, isFocusable: true),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('keeps its label while the whole label fits on one line', (tester) async {
      await tester.pumpAppScaled(
        Scaffold(
          floatingActionButton: AppFab(icon: Icons.add, label: 'Add student', onPressed: () {}),
        ),
        textScale: 1.3,
      );
      expect(find.text('Add student'), findsOneWidget);
      expect(tester.getSize(find.byType(AppFab)).width, greaterThan(56));
    });

    for (final scale in [1.0, 3.0]) {
      testWidgets('listClearance counts the home indicator when there is no bottom bar, at ${scale * 100}%', (
        tester,
      ) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpAppScaled(
          Scaffold(
            body: Builder(
              builder: (context) => ListView.builder(
                controller: controller,
                padding: EdgeInsets.only(bottom: AppFab.listClearance(context, 'Add student')),
                itemCount: 12,
                itemBuilder: (_, i) => SizedBox(height: 56, child: Text('Row $i')),
              ),
            ),
            floatingActionButton: AppFab(icon: Icons.add, label: 'Add student', onPressed: () {}),
          ),
          textScale: scale,
          bottomPadding: 34,
        );
        controller.jumpTo(controller.position.maxScrollExtent);
        await tester.pump();
        final row = tester.getRect(find.text('Row 11'));
        final fab = tester.getRect(find.byType(AppFab));
        expect(row.bottom, lessThanOrEqualTo(fab.top));
      });
    }

    for (final scale in [1.0, 1.3, 2.0, 3.0]) {
      testWidgets('listClearance lets the last row scroll clear of the button at ${scale * 100}%', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpAppScaled(
          Builder(
            builder: (context) => Scaffold(
              body: ListView.builder(
                controller: controller,
                padding: EdgeInsets.only(bottom: AppFab.listClearance(context, 'Add student')),
                itemCount: 12,
                itemBuilder: (_, i) => SizedBox(height: 56, child: Text('Row $i')),
              ),
              floatingActionButton: AppFab(icon: Icons.add, label: 'Add student', onPressed: () {}),
            ),
          ),
          textScale: scale,
        );
        controller.jumpTo(controller.position.maxScrollExtent);
        await tester.pump();
        final row = tester.getRect(find.text('Row 11'));
        final fab = tester.getRect(find.byType(AppFab));
        expect(row.bottom, lessThanOrEqualTo(fab.top), reason: 'the last row ends above the button');
      });
    }
  });

  group('StickyBottomActions', () {
    testWidgets('one primary button fills the width and reports the tap', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Scaffold(
          bottomNavigationBar: StickyBottomActions(primaryLabel: 'Add teacher', onPrimary: () => taps += 1),
        ),
      );
      expect(find.byType(OutlinedButton), findsNothing);
      final button = tester.getRect(find.byType(FilledButton));
      expect(button.height, 52);
      expect(button.width, tester.getSize(find.byType(StickyBottomActions)).width - 2 * AppSpacing.md);
      await tester.tap(find.text('Add teacher'));
      expect(taps, 1);
    });

    testWidgets('Cancel and primary sit side by side when they fit, Cancel on the left', (tester) async {
      var cancels = 0;
      var saves = 0;
      await tester.pumpApp(
        Scaffold(
          bottomNavigationBar: StickyBottomActions(
            primaryLabel: 'Save',
            onPrimary: () => saves += 1,
            secondaryLabel: 'Cancel',
            onSecondary: () => cancels += 1,
          ),
        ),
      );
      final cancel = tester.getRect(find.widgetWithText(OutlinedButton, 'Cancel'));
      final save = tester.getRect(find.widgetWithText(FilledButton, 'Save'));
      expect(cancel.top, save.top);
      expect(cancel.right, lessThan(save.left));
      expect(cancel.width, save.width);
      await tester.tap(find.text('Cancel'));
      await tester.tap(find.text('Save'));
      expect((cancels, saves), (1, 1));
    });

    testWidgets('when the labels do not fit side by side they stack with the primary on top', (tester) async {
      await tester.pumpAppScaled(
        StickyBottomActions(
          primaryLabel: 'Confirm and submit',
          onPrimary: () {},
          secondaryLabel: 'Cancel',
          onSecondary: () {},
        ),
        textScale: 2,
      );
      final cancel = tester.getRect(find.widgetWithText(OutlinedButton, 'Cancel'));
      final submit = tester.getRect(find.widgetWithText(FilledButton, 'Confirm and submit'));
      expect(submit.bottom, lessThanOrEqualTo(cancel.top));
      expect(submit.width, cancel.width);
    });

    testWidgets('a long label in another script is measured, so it stacks instead of overflowing', (tester) async {
      await tester.pumpAppScaled(
        Scaffold(
          bottomNavigationBar: StickyBottomActions(
            primaryLabel: 'उपस्थिति जमा करें और पुष्टि करें',
            onPrimary: () {},
            secondaryLabel: 'रद्द करें',
            onSecondary: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps clear of the home indicator', (tester) async {
      await tester.pumpAppScaled(
        Scaffold(
          bottomNavigationBar: StickyBottomActions(primaryLabel: 'Save', onPrimary: () {}),
        ),
        bottomPadding: 34,
      );
      final bar = tester.getRect(find.byType(StickyBottomActions));
      final button = tester.getRect(find.byType(FilledButton));
      expect(bar.bottom - button.bottom, greaterThanOrEqualTo(34 + AppSpacing.md));
    });

    testWidgets('a loading primary does nothing on tap and keeps its name', (tester) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        Scaffold(
          bottomNavigationBar: StickyBottomActions(
            primaryLabel: 'Saving',
            primaryLoading: true,
            onPrimary: () => taps += 1,
          ),
        ),
      );
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
      expect(
        tester.getSemantics(find.byType(FilledButton)),
        isSemantics(
          label: 'Saving',
          isButton: true,
          hasTapAction: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      handle.dispose();
    });

    test('needs both secondary parts or neither', () {
      expect(
        () => StickyBottomActions(primaryLabel: 'Save', onPrimary: () {}, secondaryLabel: 'Cancel'),
        throwsAssertionError,
      );
    });
  });

  group('large text on a 320 px phone: nothing is cut or broken mid-word', () {
    for (final scale in [1.0, 1.3, 2.0, 3.0]) {
      testWidgets('at ${scale * 100}%', (tester) async {
        await tester.pumpAppScaled(
          Scaffold(
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
                SliverToBoxAdapter(
                  child: AppTopBar(
                    leading: const SizedBox.square(dimension: 40),
                    overline: 'Good afternoon',
                    title: 'Kavya',
                    actions: [
                      NotificationBell(tooltip: 'Notifications', unreadLabel: '12 unread', count: 12, onPressed: () {}),
                      const Padding(padding: EdgeInsets.all(8), child: SizedBox.square(dimension: 32)),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 600)),
              ],
            ),
            floatingActionButton: AppFab(icon: Icons.add, label: 'Add student', onPressed: () {}),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StickyBottomActions(
                  primaryLabel: 'Confirm and submit',
                  onPrimary: () {},
                  secondaryLabel: 'Cancel',
                  onSecondary: () {},
                ),
                const FloatingPillNavBar(items: _fiveItems, currentIndex: 1, onSelected: _ignore),
              ],
            ),
          ),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(clippedParagraphs(tester), isEmpty);
      });
    }
  });
}

void _ignore(int _) {}
