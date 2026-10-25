// QA for app PR 3 (shell widgets): the real gallery flow into a module screen
// and back on every accent, the status bar it leaves behind, keyboard and
// screen reader order, the keyboard over a form with sticky actions, large
// text with the bundled font and Indic labels, and Reduce Motion.
import 'dart:io';

import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_avatar.dart';
import 'package:bravynix_school_erp/core/widgets/app_fab.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/floating_pill_nav_bar.dart';
import 'package:bravynix_school_erp/core/widgets/module_header.dart';
import 'package:bravynix_school_erp/core/widgets/notification_bell.dart';
import 'package:bravynix_school_erp/core/widgets/person_list_tile.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/gallery/presentation/component_gallery_page.dart';
import 'package:bravynix_school_erp/features/gallery/presentation/shell_gallery_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/clipped_text.dart';
import '../helpers/pump_app.dart';

const _scales = [1.0, 1.3, 2.0, 3.0];
const _indic = ['QaDeva', 'QaTamil', 'QaKannada'];

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(Future.value(ByteData.view(File(path).readAsBytesSync().buffer)));
  }
  await loader.load();
}

/// Pumps a few frames: the gallery has a spinning button, so it never settles.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The text drawn smaller than the phone's text size (a word that would not fit
/// otherwise), as "text: effective scale".
Map<String, double> _shrunk(WidgetTester tester, double scale) {
  final out = <String, double>{};
  // Icons, avatar initials, the bell badge (clamped at 1.5x, its count is spoken) and the gallery's
  // Material AppBar are sized on purpose.
  final exempt = find.byWidgetPredicate((w) => w is Icon || w is AppAvatar || w is NotificationBell || w is AppBar);
  for (final element in find.byType(RichText).evaluate()) {
    if (find.ancestor(of: find.byElementPredicate((e) => e == element), matching: exempt).evaluate().isNotEmpty) {
      continue;
    }
    final paragraph = element.renderObject! as RenderParagraph;
    final effective = paragraph.textScaler.scale(100) / 100;
    if (effective < scale - 0.01) out[paragraph.text.toPlainText()] = effective;
  }
  return out;
}

Future<void> _openModule(WidgetTester tester) async {
  await tester.tap(find.text('Open the shell pieces'));
  await _settle(tester);
  final button = find.text('Open a module screen');
  await tester.scrollUntilVisible(button, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(button);
  await _settle(tester);
}

/// A form screen as the app will build one: header, fields, sticky actions.
Widget _formScreen({required List<String> labels}) => Scaffold(
  body: CustomScrollView(
    slivers: [
      ModuleHeader(
        title: 'Add student',
        heroIcon: Icons.person_add_alt,
        heroTitle: 'New admission',
        onBack: () {},
        backTooltip: 'Back',
      ),
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList.list(
          children: [
            for (final label in labels)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AppTextField(label: label),
              ),
          ],
        ),
      ),
    ],
  ),
  bottomNavigationBar: StickyBottomActions(
    primaryLabel: 'Save student',
    onPrimary: () {},
    secondaryLabel: 'Cancel',
    onSecondary: () {},
  ),
);

void main() {
  setUpAll(() async {
    await _loadFont(AppTextStyles.family, [
      for (final w in [400, 500, 600, 700]) 'assets/fonts/plus_jakarta_sans/PlusJakartaSans-$w.ttf',
    ]);
    const noto = 'test/fixtures/fonts/noto';
    await _loadFont('QaDeva', ['$noto/NotoSans-devanagari.ttf']);
    await _loadFont('QaTamil', ['$noto/NotoSans-tamil.ttf']);
    await _loadFont('QaKannada', ['$noto/NotoSans-kannada.ttf']);
  });

  group('gallery flow on every accent', () {
    for (final accent in AppAccent.values) {
      testWidgets('${accent.label}: into a module screen and back; status bar; Tab order; white ring', (tester) async {
        final handle = tester.ensureSemantics();
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
        addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
        await tester.pumpAppScaled(const ComponentGalleryPage(), size: const Size(360, 780));
        await _settle(tester);
        await tester.tap(find.text(accent.label));
        await _settle(tester);
        await _openModule(tester);

        // The module screen is in the chosen accent, with light status bar icons.
        final header = tester.widget<ColoredBox>(
          find.descendant(of: find.byType(ModuleHeader), matching: find.byType(ColoredBox)).first,
        );
        expect(header.color, AppTheme.light(accent: accent).colorScheme.primary);
        expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.light);
        expect(tester.takeException(), isNull);

        // Tab order: back, bell, the FAB, Cancel, the primary. Each header button gets a white ring.
        final order = <String>[];
        for (var i = 0; i < 5; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final element = FocusManager.instance.primaryFocus!.context!;
          final focused = find.byElementPredicate((e) => e == element);
          String name;
          if (find.ancestor(of: focused, matching: find.byType(NotificationBell)).evaluate().isNotEmpty) {
            name = 'Notifications';
          } else if (find.ancestor(of: focused, matching: find.byType(AppFab)).evaluate().isNotEmpty) {
            name = 'Add student';
          } else {
            final button = find.ancestor(
              of: focused,
              matching: find.byWidgetPredicate((w) => w is IconButton || w is ButtonStyleButton),
            );
            final texts = find.descendant(of: button.first, matching: find.byType(Text));
            final tooltip = tester.widgetList(button).whereType<IconButton>().firstOrNull?.tooltip;
            name = tooltip ?? (texts.evaluate().isEmpty ? '?' : tester.widget<Text>(texts.first).data!);
          }
          order.add(name);
          if (i < 2) {
            final material = tester.widget<Material>(find.ancestor(of: focused, matching: find.byType(Material)).first);
            final side = (material.shape! as OutlinedBorder).side;
            expect(side.color, Colors.white, reason: 'ring on $name');
            expect(side.width, 2);
          }
        }
        // The bar's two buttons follow their visual order: Cancel first side by side, the primary first when stacked.
        final cancel = tester.getRect(find.text('Cancel'));
        final confirm = tester.getRect(find.text('Confirm and submit'));
        final cancelFirst =
            cancel.top < confirm.top - 1 || (cancel.top - confirm.top).abs() <= 1 && cancel.left < confirm.left;
        expect(order, [
          'Back',
          'Notifications',
          'Add student',
          if (cancelFirst) ...['Cancel', 'Confirm and submit'] else ...['Confirm and submit', 'Cancel'],
        ]);

        // Enter on Back leaves the module; the plain AppBar page has dark icons again.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        for (var i = 0; i < 1; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _settle(tester);
        expect(find.byType(ModuleHeader), findsNothing);
        expect(find.text('Open a module screen'), findsOneWidget);
        expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.dark);
        handle.dispose();
      });
    }
  });

  group('screen reader order on the module screen', () {
    testWidgets('title row before the hero, the bell with its count, then the list, the FAB and the bar', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpAppScaled(const ComponentGalleryPage(), size: const Size(360, 780));
      await _settle(tester);
      await _openModule(tester);
      final spoken = [
        for (final node in tester.semantics.simulatedAccessibilityTraversal())
          if (node.getSemanticsData().label.isNotEmpty) node.getSemanticsData().label.replaceAll('\n', ' '),
      ];
      int at(String start) => spoken.indexWhere((s) => s.startsWith(start));
      expect(at('Back'), lessThan(at('Attendance')));
      expect(at('Attendance'), lessThan(at('Mark attendance')));
      expect(at('Notifications'), lessThan(at('Mark attendance')));
      expect(at('Mark attendance'), lessThan(at('Student 1')));
      expect(at('Add student'), greaterThan(at('Student 1')));
      expect(at('Confirm and submit'), greaterThan(at('Add student')));

      // Collapsed, the faded hero card is not read at all.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await _settle(tester);
      final collapsed = [
        for (final node in tester.semantics.simulatedAccessibilityTraversal()) node.getSemanticsData().label,
      ];
      expect(collapsed.any((s) => s.contains('Mark attendance')), isFalse);
      handle.dispose();
    });

    testWidgets('bell and tabs: name, unread count, tab position and state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpAppScaled(const ShellGalleryPage(), size: const Size(360, 780));
      await _settle(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Notifications'))),
        isSemantics(label: 'Notifications, 12 unread', isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Attendance')),
        isSemantics(label: 'Attendance', hint: 'Tab 2 of 3', isSelected: false, hasTapAction: true),
      );
      await tester.tap(find.bySemanticsLabel('Attendance'));
      await _settle(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Attendance')),
        isSemantics(label: 'Attendance', isSelected: true),
      );
      handle.dispose();
    });
  });

  group('large text on a 320 x 640 phone', () {
    for (final scale in _scales) {
      testWidgets('scale $scale: shell page and module screen, nothing cut, layout errors or overlap', (tester) async {
        await tester.pumpAppScaled(const ComponentGalleryPage(), textScale: scale);
        await _settle(tester);
        await tester.scrollUntilVisible(
          find.text('Open the shell pieces'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Open the shell pieces'));
        await _settle(tester);
        await tester.tap(find.text('Open the shell pieces'));
        await _settle(tester);
        final cut = <String>{};
        final shrunk = <String, double>{};
        final list = find.descendant(of: find.byType(ShellGalleryPage), matching: find.byType(Scrollable)).first;
        for (var i = 0; i < 60; i++) {
          cut.addAll(clippedParagraphs(tester, within: find.byType(ShellGalleryPage)));
          shrunk.addAll(_shrunk(tester, scale));
          expect(tester.takeException(), isNull);
          final position = tester.state<ScrollableState>(list).position;
          if (position.pixels >= position.maxScrollExtent) break;
          await tester.drag(list, const Offset(0, -250));
          await _settle(tester);
        }
        await tester.scrollUntilVisible(find.text('Open a module screen'), 100, scrollable: list);
        await tester.ensureVisible(find.text('Open a module screen'));
        await _settle(tester);
        await tester.tap(find.text('Open a module screen'));
        await _settle(tester);
        final module = find.byType(CustomScrollView);
        for (var i = 0; i < 60; i++) {
          cut.addAll(clippedParagraphs(tester, within: find.byType(Scaffold).last));
          shrunk.addAll(_shrunk(tester, scale));
          expect(tester.takeException(), isNull);
          final position = tester
              .state<ScrollableState>(find.descendant(of: module, matching: find.byType(Scrollable)))
              .position;
          if (position.pixels >= position.maxScrollExtent) break;
          await tester.drag(module, const Offset(0, -150));
          await _settle(tester);
        }
        // At the end of the list the last row must be clear of the FAB and the bar, so it can be read and tapped.
        final last = tester.getRect(find.byType(PersonListTile).last);
        final fab = tester.getRect(find.byType(AppFab));
        final bar = tester.getRect(find.byType(StickyBottomActions));
        final problems = [
          ...cut,
          if (last.bottom > bar.top + 0.5) 'last row $last is under the bar $bar',
          if (last.overlaps(fab)) 'last row $last is under the FAB $fab',
        ];
        // A word may be drawn smaller only when it cannot fit a full line; never below 2x at 3.0.
        for (final MapEntry(key: text, value: effective) in shrunk.entries) {
          if (effective < scale * 0.66) problems.add('"$text" drawn at ${effective.toStringAsFixed(2)}x');
        }
        expect(problems, isEmpty);
      });
    }
  });

  group('the keyboard over a form with sticky actions', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('scale $scale: iPhone with home indicator, keyboard 336 px: bar above it, focused field visible', (
        tester,
      ) async {
        const size = Size(390, 844);
        const keyboard = 336.0;
        final labels = [for (var i = 1; i <= 8; i++) 'Field $i'];
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1
          ..padding = const FakeViewPadding(top: 47, bottom: 34)
          ..viewPadding = const FakeViewPadding(top: 47, bottom: 34);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: _formScreen(labels: labels),
          ),
        );
        await tester.pumpAndSettle();
        final restBar = tester.getRect(find.byType(StickyBottomActions));
        expect(restBar.bottom, size.height);

        // Focus the last field, then the keyboard opens (as the engine reports it: padding drops to 0).
        await tester.showKeyboard(find.byType(TextField).last);
        tester.view
          ..viewInsets = const FakeViewPadding(bottom: keyboard)
          ..padding = const FakeViewPadding(top: 47);
        await tester.pumpAndSettle();
        final bar = tester.getRect(
          find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(Material)).first,
        );
        expect(bar.bottom, closeTo(size.height - keyboard, 0.5), reason: 'bar should sit on the keyboard');
        // The scrolling body ends at the bar, so revealing the focused field targets the space above the bar.
        // (Whether the caret is then scrolled into view is Flutter's own EditableText behaviour; this test
        // harness does not replay it even for a plain Scaffold, so that part is checked on a device.)
        final viewport = tester.getRect(find.byType(Viewport).first);
        expect(viewport.bottom, closeTo(bar.top, 0.5));
        // The last field can be scrolled fully above the bar (and below the pinned header).
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
        await tester.pumpAndSettle();
        final last = tester.getRect(find.byType(TextField).last);
        expect(last.bottom, lessThanOrEqualTo(bar.top + 0.5));
        expect(
          last.top,
          greaterThanOrEqualTo(
            tester
                .getRect(find.descendant(of: find.byType(ModuleHeader), matching: find.byType(ColoredBox)).first)
                .bottom,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(clippedParagraphs(tester), isEmpty);

        // Keyboard closed again: back at the bottom, clear of the home indicator.
        tester.view
          ..viewInsets = FakeViewPadding.zero
          ..padding = const FakeViewPadding(top: 47, bottom: 34);
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(StickyBottomActions)), restBar);
      });
    }
  });

  group('Indic labels at large text', () {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('scale $scale: tabs, FAB, sticky actions and header in Hindi, Tamil and Kannada', (tester) async {
        var tab = 1;
        await tester.pumpAppScaled(
          Builder(
            builder: (context) {
              final theme = AppTheme.light();
              return Theme(
                data: theme.copyWith(textTheme: theme.textTheme.apply(fontFamilyFallback: _indic)),
                child: StatefulBuilder(
                  builder: (context, setState) => Scaffold(
                    body: CustomScrollView(
                      slivers: [
                        ModuleHeader(
                          title: 'ವಿದ್ಯಾರ್ಥಿಗಳ ಹಾಜರಾತಿ',
                          heroIcon: Icons.event_available_outlined,
                          heroTitle: 'உங்கள் பிரிவின் வருகை',
                          description: 'आज की उपस्थिति दर्ज करें',
                          onBack: () {},
                          backTooltip: 'वापस',
                          actions: [NotificationBell(tooltip: 'सूचनाएँ', onPressed: () {}, count: 3, onAccent: true)],
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 900)),
                      ],
                    ),
                    floatingActionButton: AppFab(icon: Icons.add, label: 'विद्यार्थी जोड़ें', onPressed: () {}),
                    bottomNavigationBar: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StickyBottomActions(
                          primaryLabel: 'சமர்ப்பிக்கவும்',
                          onPrimary: () {},
                          secondaryLabel: 'ರದ್ದುಮಾಡಿ',
                          onSecondary: () {},
                        ),
                        FloatingPillNavBar(
                          currentIndex: tab,
                          onSelected: (i) => setState(() => tab = i),
                          items: const [
                            PillNavItem(icon: Icons.home_outlined, label: 'मुख्य पृष्ठ'),
                            PillNavItem(icon: Icons.event_available_outlined, label: 'உபஸ்திதி வருகைப் பதிவு'),
                            PillNavItem(icon: Icons.payments_outlined, label: 'ಶುಲ್ಕ'),
                            PillNavItem(icon: Icons.person_outline, label: 'प्रोफ़ाइल'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          textScale: scale,
          size: const Size(320, 900),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(clippedParagraphs(tester, unbreakable: 320 - 2 * 16), isEmpty);
        for (var i = 0; i < 4; i++) {
          await tester.tap(find.descendant(of: find.byType(FloatingPillNavBar), matching: find.byType(InkWell)).at(i));
          await tester.pumpAndSettle();
          expect(tab, i);
          expect(tester.takeException(), isNull);
          expect(clippedParagraphs(tester, unbreakable: 320 - 2 * 16), isEmpty);
        }
      });
    }
  });

  group('Reduce Motion', () {
    testWidgets('iOS Reduce Motion: switching tabs resizes the pills in the same frame', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pumpAppScaled(const ShellGalleryPage(), size: const Size(360, 780));
      await _settle(tester);
      // With Reduce Motion the tab has no AnimatedSize at all, so find the tab by its tooltip.
      final attendance = find.byTooltip('Attendance');
      final before = tester.getSize(attendance).width;
      await tester.tap(attendance);
      await tester.pump();
      await tester.pump();
      final after = tester.getSize(attendance).width;
      expect(after, greaterThan(before + 20), reason: 'the chosen pill should be full width at once');
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getSize(attendance).width, after);
    });

    testWidgets(
      'without Reduce Motion the same switch animates over 200 ms (the tab must not be rebuilt from scratch)',
      (tester) async {
        await tester.pumpAppScaled(const ShellGalleryPage(), size: const Size(360, 780));
        await _settle(tester);
        final attendance = find
            .descendant(of: find.byType(FloatingPillNavBar), matching: find.byType(AnimatedSize))
            .at(1);
        await tester.tap(attendance);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        final mid = tester.getSize(attendance).width;
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.getSize(attendance).width, greaterThan(mid));
      },
    );
  });
}
