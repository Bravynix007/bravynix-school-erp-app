import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/gallery/presentation/component_gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The gallery has a loading button whose spinner never stops, so
/// pumpAndSettle would never return.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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
      for (var i = 0; i < 32; i += 1) {
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
    await _settle(tester);
    expect(find.text('Add a note'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await _settle(tester);
    await tester.scrollUntilVisible(find.text('Open confirm dialog'), 400, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Open confirm dialog'));
    await _settle(tester);
    expect(find.text('Delete this class?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the module screen opens from the gallery and its header shrinks when scrolled', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Open the shell pieces'));
    await _settle(tester);
    expect(find.text('Fee receipt'), findsOneWidget, reason: 'the back variant of the top bar');
    await tester.scrollUntilVisible(find.text('Open a module screen'), 400, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Open a module screen'));
    await _settle(tester);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text("Mark today's attendance for your section"), findsOneWidget);
    final header = find.descendant(of: find.byType(SliverPersistentHeader), matching: find.byType(ColoredBox)).first;
    final expanded = tester.getSize(header).height;
    expect(expanded, greaterThanOrEqualTo(260));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await _settle(tester);
    expect(tester.getSize(header).height, lessThan(expanded));
    expect(find.text('Attendance'), findsOneWidget, reason: 'the title stays pinned');
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.3, 2.0, 3.0]) {
    testWidgets('the shell page lays out at ${scale * 100}% text on a 320 px phone from top to bottom', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(size: const Size(320, 640), textScaler: TextScaler.linear(scale)),
            child: const ComponentGalleryPage(),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Open the shell pieces'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Open the shell pieces'));
      await tester.pump();
      await tester.tap(find.text('Open the shell pieces'));
      await _settle(tester);
      expect(find.text('Fee receipt'), findsOneWidget, reason: 'the shell page is open');
      for (var i = 0; i < 12; i += 1) {
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'screen $i at $scale');
      }
    });
  }
}
