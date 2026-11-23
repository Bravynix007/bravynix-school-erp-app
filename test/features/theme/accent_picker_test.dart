import 'package:bravynix_school_erp/core/storage/accent_choice_store.dart';
import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/features/theme/presentation/accent_picker.dart';
import 'package:bravynix_school_erp/features/theme/presentation/bloc/accent_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  late AccentBloc bloc;

  // The bloc is made inside the test, so its streams run on the test's clock.
  Future<void> pump(WidgetTester tester, {double textScale = 1}) => tester.pumpAppScaled(
    BlocProvider(
      create: (_) => bloc = AccentBloc(InMemoryAccentChoiceStore()),
      child: const Scaffold(body: AccentPicker()),
    ),
    textScale: textScale,
  );

  testWidgets('offers the seven accents, the one in use marked with a check', (tester) async {
    await pump(tester);
    expect(find.text('Theme colour'), findsOneWidget);
    for (final accent in AppAccent.values) {
      expect(find.byKey(Key('accent.${accent.name}')), findsOneWidget);
    }
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const Key('accent.teal')), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
  });

  testWidgets('tapping an accent chooses it and moves the check', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('accent.rosePink')));
    await tester.pumpAndSettle();
    expect(bloc.state.accent, AppAccent.rosePink);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const Key('accent.rosePink')), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
  });

  testWidgets('each swatch is a button named by its colour, and the chosen one says so', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(find.byKey(const Key('accent.teal'))),
      matchesSemantics(
        label: 'BravyNix Teal',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('accent.royalPurple'))),
      matchesSemantics(
        label: 'Royal Purple',
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('says each accent by the name the app gives it', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    const names = {
      AppAccent.teal: 'BravyNix Teal',
      AppAccent.forestGreen: 'Forest Green',
      AppAccent.royalPurple: 'Royal Purple',
      AppAccent.steelBlue: 'Steel Blue',
      AppAccent.rosePink: 'Rose Pink',
      AppAccent.sunsetOrange: 'Sunset Orange',
      AppAccent.darkCyan: 'Dark Cyan',
    };
    for (final MapEntry(key: accent, value: name) in names.entries) {
      expect(tester.getSemantics(find.byKey(Key('accent.${accent.name}'))).label, name);
    }
    semantics.dispose();
  });

  testWidgets('draws the ring on the chosen swatch only, and moves it with the choice', (tester) async {
    await pump(tester);
    Border? ringOf(AppAccent accent) {
      final box = tester.widget<Container>(find.byKey(Key('accent.${accent.name}.fill')));
      return (box.decoration! as BoxDecoration).border as Border?;
    }

    expect(ringOf(AppAccent.teal), Border.all(color: AppColors.ink, width: 2));
    for (final accent in AppAccent.values.skip(1)) {
      expect(ringOf(accent), isNull, reason: accent.name);
    }
    await tester.tap(find.byKey(const Key('accent.steelBlue')));
    await tester.pumpAndSettle();
    expect(ringOf(AppAccent.steelBlue), Border.all(color: AppColors.ink, width: 2));
    expect(ringOf(AppAccent.teal), isNull);
  });

  testWidgets('every swatch is at least 48 px square, at the largest text size too', (tester) async {
    await pump(tester, textScale: 2);
    for (final accent in AppAccent.values) {
      final size = tester.getSize(find.byKey(Key('accent.${accent.name}')));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });
}
