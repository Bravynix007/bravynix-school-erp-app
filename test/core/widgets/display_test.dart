import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_avatar.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_tag.dart';
import 'package:bravynix_school_erp/core/widgets/audit_footer.dart';
import 'package:bravynix_school_erp/core/widgets/menu_list_tile.dart';
import 'package:bravynix_school_erp/core/widgets/person_list_tile.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/stat_tile.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/contrast.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('StatusChip', () {
    test('every tone is readable on its own background', () {
      for (final tone in StatusTone.values) {
        expect(contrast(tone.foreground, tone.background), greaterThanOrEqualTo(4.5), reason: tone.name);
      }
    });

    testWidgets('shows an icon with the label, so colour is never the only cue', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: StatusChip(label: 'Overdue', tone: StatusTone.error),
        ),
      );
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('showIcon: false leaves only the label', (tester) async {
      await tester.pumpApp(const Scaffold(body: StatusChip(label: 'Draft', showIcon: false)));
      expect(find.byType(Icon), findsNothing);
    });
  });

  testWidgets('AppTag is accent text on the accent wash, and follows the accent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(accent: AppAccent.steelBlue),
        home: const Scaffold(body: AppTag('Class 7-B')),
      ),
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(AppTag), matching: find.byType(DecoratedBox)),
    );
    expect((box.decoration as BoxDecoration).color, AppAccent.steelBlue.tint);
    expect(tester.widget<Text>(find.text('Class 7-B')).style?.color, AppAccent.steelBlue.text);
  });

  group('AppAvatar', () {
    test('initials: two words give two letters, one word gives one, blank gives ?', () {
      expect(AppAvatar.initialsOf('Asha Rao'), 'AR');
      expect(AppAvatar.initialsOf('  vikram  kumar shah '), 'VS');
      expect(AppAvatar.initialsOf('Meera'), 'M');
      expect(AppAvatar.initialsOf('   '), '?');
    });

    testWidgets('speaks the name once, not the initials', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(const Scaffold(body: AppAvatar(name: 'Asha Rao')));
      expect(find.bySemanticsLabel('Asha Rao'), findsOneWidget);
      expect(find.bySemanticsLabel('AR'), findsNothing);
      handle.dispose();
    });

    testWidgets('sizes are 32, 40 and 56 px', (tester) async {
      for (final size in AvatarSize.values) {
        await tester.pumpApp(
          Scaffold(
            body: Center(
              child: AppAvatar(key: ValueKey(size), name: 'Asha Rao', size: size),
            ),
          ),
        );
        expect(tester.getSize(find.byType(CircleAvatar)), Size.square(size.dimension));
      }
    });
  });

  testWidgets('AppCard is a button only when it has onTap', (tester) async {
    var taps = 0;
    await tester.pumpApp(
      Scaffold(
        body: Column(
          children: [
            const AppCard(child: Text('Plain')),
            AppCard(onTap: () => taps += 1, child: const Text('Tappable')),
          ],
        ),
      ),
    );
    expect(find.descendant(of: find.widgetWithText(AppCard, 'Plain'), matching: find.byType(InkWell)), findsNothing);
    await tester.tap(find.text('Tappable'));
    expect(taps, 1);
  });

  testWidgets('SectionHeader is a heading, with an optional action', (tester) async {
    final handle = tester.ensureSemantics();
    var tapped = false;
    await tester.pumpApp(
      Scaffold(
        body: SectionHeader(title: 'Today', actionLabel: 'See all', onAction: () => tapped = true),
      ),
    );
    expect(tester.getSemantics(find.text('Today')), matchesSemantics(label: 'Today', isHeader: true));
    await tester.tap(find.text('See all'));
    expect(tapped, isTrue);
    handle.dispose();
  });

  group('lists', () {
    testWidgets('PersonListTile shows name, detail and trailing, and taps', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Scaffold(
          body: PersonListTile(
            name: 'Asha Rao',
            subtitle: 'Class 7-B',
            trailing: const StatusChip(label: 'Paid', tone: StatusTone.success),
            onTap: () => taps += 1,
          ),
        ),
      );
      expect(find.text('Asha Rao'), findsOneWidget);
      expect(find.text('Class 7-B'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      await tester.tap(find.text('Asha Rao'));
      expect(taps, 1);
      expect(tester.getSize(find.byType(PersonListTile)).height, greaterThanOrEqualTo(56));
    });

    testWidgets('MenuListTile destructive is red and has no chevron', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: Column(
            children: [
              MenuListTile(icon: Icons.person, title: 'Profile', onTap: () {}),
              MenuListTile(icon: Icons.logout, title: 'Log out', destructive: true, onTap: () {}),
            ],
          ),
        ),
      );
      expect(tester.widget<Text>(find.text('Log out')).style?.color, AppColors.error);
      expect(tester.widget<Text>(find.text('Profile')).style?.color, AppColors.ink);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('a person row reads as one item, with the name once', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        Scaffold(
          body: PersonListTile(
            name: 'Asha Rao',
            subtitle: 'Class 7-B',
            trailing: const StatusChip(label: 'Paid', tone: StatusTone.success),
            onTap: () {},
          ),
        ),
      );
      expect(find.bySemanticsLabel(RegExp('Asha Rao')), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Asha Rao'))).label,
        allOf(contains('Class 7-B'), contains('Paid')),
      );
      handle.dispose();
    });

    testWidgets('at 200% text a person row is drawn at 200%, keeps its name wide, and puts the chip under it', (
      tester,
    ) async {
      Future<void> pump(double scale) => tester.pumpAppScaled(
        Scaffold(
          body: ListView(
            children: const [
              PersonListTile(
                name: 'Venkata Satya Rao',
                subtitle: 'Class 7-B · Roll 14',
                trailing: StatusChip(label: 'Partly paid', tone: StatusTone.warning),
              ),
            ],
          ),
        ),
        textScale: scale,
      );
      await pump(1);
      final nameAt1 = tester.textHeight('Venkata Satya Rao');
      final chip = tester.getRect(find.text('Partly paid'));
      final name = tester.getRect(find.text('Venkata Satya Rao'));
      expect(chip.top, lessThan(name.bottom), reason: 'beside the name at 1x');
      expect(chip.left, greaterThan(name.left));
      await pump(2);
      expect(tester.takeException(), isNull);
      expect(tester.textHeight('Venkata Satya Rao'), greaterThanOrEqualTo(nameAt1 * 1.9));
      expect(tester.getSize(find.text('Venkata Satya Rao')).width, greaterThan(120), reason: 'the name is not crushed');
      expect(
        tester.getTopLeft(find.text('Partly paid')).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.text('Class 7-B · Roll 14')).dy),
        reason: 'under the detail line at 200%',
      );
    });

    testWidgets('menu rows, stat tiles and footers lay out at 200% on a narrow phone', (tester) async {
      await tester.pumpAppScaled(
        Scaffold(
          body: ListView(
            children: [
              MenuListTile(icon: Icons.person, title: 'Profile and language', subtitle: 'Name, phone', onTap: () {}),
              const StatTile(label: 'Fees due this term', value: '₹1,24,500', note: '18 students'),
              const AuditFooter(lines: ['Added by Asha Rao on 3 Mar 2026', 'Updated by Ravi Kumar on 9 Mar 2026']),
            ],
          ),
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.textHeight('₹1,24,500'),
        greaterThan(40),
        reason: 'headlineMedium 20 px at 200% is 28 px lines scaled',
      );
    });

    testWidgets('tappable menu rows and cards speak as buttons', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        Scaffold(
          body: Column(
            children: [
              MenuListTile(icon: Icons.person, title: 'Profile', onTap: () {}),
              AppCard(onTap: () {}, child: const Text('Card')),
            ],
          ),
        ),
      );
      expect(tester.getSemantics(find.bySemanticsLabel('Profile')).flagsCollection.isButton, isTrue);
      expect(tester.getSemantics(find.bySemanticsLabel('Card')).flagsCollection.isButton, isTrue);
      handle.dispose();
    });
  });

  testWidgets('a focused tappable AppCard draws the ring inside the rounded corners', (tester) async {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
    await tester.pumpApp(
      Scaffold(
        body: AppCard(onTap: () {}, child: const Text('Card')),
      ),
    );
    expect(tester.widget<Card>(find.byType(Card)).borderOnForeground, isFalse, reason: 'hairline stays under the ring');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final ring = tester
        .widgetList<DecoratedBox>(find.descendant(of: find.byType(AppCard), matching: find.byType(DecoratedBox)))
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .singleWhere((d) => d.border != null);
    expect(ring.borderRadius, BorderRadius.circular(AppRadius.card));
    expect((ring.border! as Border).top.color, AppColors.focusRing);
    expect((ring.border! as Border).top.width, 2);
  });

  testWidgets('StatTile shows label, figure and note, with tabular figures', (tester) async {
    await tester.pumpApp(
      const Scaffold(
        body: StatTile(label: 'Present today', value: '412', note: '96% of 429'),
      ),
    );
    expect(find.text('Present today'), findsOneWidget);
    expect(find.text('96% of 429'), findsOneWidget);
    expect(tester.widget<Text>(find.text('412')).style?.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  testWidgets('AuditFooter lists each line', (tester) async {
    await tester.pumpApp(const Scaffold(body: AuditFooter(lines: ['Added by Asha', 'Updated by Ravi'])));
    expect(find.text('Added by Asha'), findsOneWidget);
    expect(find.text('Updated by Ravi'), findsOneWidget);
  });
}
