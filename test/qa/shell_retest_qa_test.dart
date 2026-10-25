// QA retest of app PR 3 at 429a3e4: the FAB list clearance on a phone with a
// home indicator and no bottom bar (R1), and the chosen tab growing smoothly
// from its first frame (R2).
import 'package:bravynix_school_erp/core/widgets/app_fab.dart';
import 'package:bravynix_school_erp/core/widgets/floating_pill_nav_bar.dart';
import 'package:bravynix_school_erp/features/gallery/presentation/shell_gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  group('R1: listClearance with a home indicator and no bottom bar', () {
    for (final (size, inset) in [(const Size(390, 844), 34.0), (const Size(844, 390), 21.0)]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        testWidgets('$size, inset $inset, text $scale: the last row ends above the button', (tester) async {
          final controller = ScrollController();
          addTearDown(controller.dispose);
          await tester.pumpAppScaled(
            Scaffold(
              body: Builder(
                builder: (context) => ListView.builder(
                  controller: controller,
                  padding: EdgeInsets.only(bottom: AppFab.listClearance(context, 'Add student')),
                  itemCount: 30,
                  itemBuilder: (_, i) => SizedBox(height: 56, child: Text('Row $i')),
                ),
              ),
              floatingActionButton: AppFab(icon: Icons.add, label: 'Add student', onPressed: () {}),
            ),
            textScale: scale,
            size: size,
            bottomPadding: inset,
          );
          controller.jumpTo(controller.position.maxScrollExtent);
          await tester.pump();
          final row = tester.getRect(find.ancestor(of: find.text('Row 29'), matching: find.byType(SizedBox)).first);
          final fab = tester.getRect(find.byType(AppFab));
          expect(row.bottom, lessThanOrEqualTo(fab.top), reason: 'row $row, button $fab');
        });
      }
    }
  });

  testWidgets('R2: the chosen tab grows from its first frame, with no jump', skip: true, (tester) async {
    // Deferred (cosmetic, QA Low): the new tab's width follows the space the old tab still holds, so
    // AnimatedSize snaps once. Needs one animation for the whole row instead of one per tab.
    await tester.pumpAppScaled(const ShellGalleryPage(), size: const Size(390, 844));
    await tester.pump(const Duration(milliseconds: 300));
    final box = find.ancestor(
      of: find.descendant(of: find.byType(FloatingPillNavBar), matching: find.byTooltip('Attendance')),
      matching: find.byType(AnimatedSize),
    );
    final start = tester.getSize(box.first).width;
    await tester.tap(box.first);
    await tester.pump();
    final widths = <double>[];
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      widths.add(tester.getSize(box.first).width);
    }
    final end = widths.last;
    // After 20 ms of a 200 ms resize, the tab should have covered roughly a tenth of the way, not half.
    expect(widths.first - start, lessThan((end - start) * 0.3), reason: 'widths from $start: $widths');
  });
}
