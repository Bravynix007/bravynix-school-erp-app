import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/gallery/presentation/component_gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {double textScale = 1}) async {
  tester.view
    ..physicalSize = const Size(360, 740)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: const Size(360, 740), textScaler: TextScaler.linear(textScale)),
        child: const ComponentGalleryPage(),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the shared widgets without errors, scrolled to the end', (tester) async {
    await _pump(tester);
    expect(find.text('Component gallery'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Open confirm dialog'), 500, scrollable: find.byType(Scrollable).first);
    expect(find.text('Open confirm dialog'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('lays out at ${scale * 100}% text on a 360 px phone from top to bottom', (tester) async {
      await _pump(tester, textScale: scale);
      for (var i = 0; i < 25; i += 1) {
        await tester.drag(find.byType(ListView), const Offset(0, -700));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'screen $i at $scale');
      }
    });
  }

  testWidgets('choosing an accent recolours the primary button, and nothing neutral', (tester) async {
    await _pump(tester);
    Color? buttonFill() {
      final material = find
          .descendant(of: find.widgetWithText(FilledButton, 'Save changes'), matching: find.byType(Material))
          .first;
      return tester.widget<Material>(material).color;
    }

    expect(buttonFill(), AppAccent.teal.primary);
    await tester.tap(find.text('Rose Pink'));
    await tester.pump();
    expect(buttonFill(), AppAccent.rosePink.primary);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, isNull);
    expect(Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor, AppColors.canvas);
  });

  testWidgets('every accent can be chosen without errors', (tester) async {
    await _pump(tester);
    for (final accent in AppAccent.values) {
      await tester.tap(find.text(accent.label));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: accent.label);
    }
  });

  testWidgets('the sheet and the dialog open from the gallery', (tester) async {
    await _pump(tester);
    await tester.scrollUntilVisible(find.text('Open bottom sheet'), 400, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Open bottom sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Add a note'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Open confirm dialog'), 400, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Open confirm dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this class?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
