import 'package:bravynix_school_erp/core/theme/app_colors.dart';
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

    testWidgets('rows stay readable at 200% text on a narrow phone', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: ListView(
                children: [
                  const PersonListTile(
                    name: 'Venkata Satya Prasad Rao',
                    subtitle: 'Class 7-B · Roll 14',
                    trailing: StatusChip(label: 'Overdue', tone: StatusTone.error),
                  ),
                  MenuListTile(
                    icon: Icons.person,
                    title: 'Profile and language',
                    subtitle: 'Name, phone',
                    onTap: () {},
                  ),
                  const StatTile(label: 'Fees due this term', value: '₹1,24,500', note: '18 students'),
                  const AuditFooter(lines: ['Added by Asha Rao on 3 Mar 2026', 'Updated by Ravi Kumar on 9 Mar 2026']),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
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
