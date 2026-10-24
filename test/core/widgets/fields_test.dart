import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_date_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_search_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppTextField', () {
    testWidgets('shows the label above the field and takes typing', (tester) async {
      String? typed;
      await tester.pumpApp(
        Scaffold(
          body: AppTextField(label: 'Student name', onChanged: (v) => typed = v),
        ),
      );
      expect(find.text('Student name'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Asha');
      expect(typed, 'Asha');
    });

    testWidgets('a required field shows a red star that screen readers skip, and is flagged required', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const Scaffold(
          body: AppTextField(label: 'Name', required: true, requiredLabel: 'Required'),
        ),
      );
      final label = tester.widget<Text>(
        find.byWidgetPredicate((w) => w is Text && (w.textSpan?.toPlainText() ?? '') == 'Name *'),
      );
      expect(find.ancestor(of: find.byWidget(label), matching: find.byType(ExcludeSemantics)), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(label: 'Name', hint: 'Required', isRequired: true, hasRequiredState: true),
      );
      expect(find.bySemanticsLabel(RegExp('required')), findsNothing);
      handle.dispose();
    });

    testWidgets('a required field must be given the spoken word, so none is hard-coded', (tester) async {
      await tester.pumpApp(const Scaffold(body: AppTextField(label: 'Name', required: true)));
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('shows helper text, and the error replaces it', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: AppTextField(label: 'Mobile', helper: 'Ten digits'),
        ),
      );
      expect(find.text('Ten digits'), findsOneWidget);
      await tester.pumpApp(
        const Scaffold(
          body: AppTextField(label: 'Mobile', helper: 'Ten digits', error: 'Too short'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Too short'), findsOneWidget);
      expect(find.text('Ten digits'), findsNothing);
    });

    testWidgets('a mono field sets tabular figures', (tester) async {
      await tester.pumpApp(const Scaffold(body: AppTextField(label: 'ID', mono: true)));
      final style = tester.widget<TextField>(find.byType(TextField)).style;
      expect(style?.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    testWidgets('a disabled field is marked disabled, and the theme gives it the lighter outline', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: Column(
            children: [
              AppTextField(label: 'On'),
              AppTextField(label: 'Off', enabled: false),
            ],
          ),
        ),
      );
      final decorators = tester.widgetList<InputDecorator>(find.byType(InputDecorator)).toList();
      expect(decorators[0].decoration.enabled, isTrue);
      expect(decorators[1].decoration.enabled, isFalse);
      final theme = Theme.of(tester.element(find.byType(InputDecorator).first)).inputDecorationTheme;
      expect(theme.enabledBorder?.borderSide.color, AppColors.fieldBorder);
      expect(theme.disabledBorder?.borderSide.color, AppColors.divider);
    });
  });

  group('AppDropdownField', () {
    const items = [
      DropdownMenuItem(value: 'A', child: Text('Section A')),
      DropdownMenuItem(value: 'B', child: Text('Section B')),
    ];

    testWidgets('shows the chosen value and reports a new choice', (tester) async {
      String? value = 'A';
      await tester.pumpApp(
        StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: AppDropdownField<String>(
              label: 'Class',
              value: value,
              items: items,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      expect(find.text('Section A'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Section B').last);
      await tester.pumpAndSettle();
      expect(value, 'B');
      expect(find.text('Section B'), findsOneWidget);
    });

    testWidgets('follows a value changed by the screen', (tester) async {
      Future<void> pump(String? value) => tester.pumpApp(
        Scaffold(
          body: AppDropdownField<String>(label: 'Class', value: value, items: items, onChanged: (_) {}),
        ),
      );
      await pump('A');
      expect(find.text('Section A'), findsOneWidget);
      await pump('B');
      expect(find.text('Section B'), findsOneWidget);
    });

    testWidgets('is as tall as a text field, and shows the error and the disabled state like one', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: Column(
            children: [
              const AppTextField(key: Key('text'), label: 'Name'),
              AppDropdownField<String>(key: const Key('drop'), label: 'Class', items: items, onChanged: (_) {}),
              const AppDropdownField<String>(key: Key('off'), label: 'Class', items: items, onChanged: null),
              AppDropdownField<String>(
                key: const Key('err'),
                label: 'Class',
                items: items,
                error: 'Pick a class',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      double fieldHeight(String key) =>
          tester.getSize(find.descendant(of: find.byKey(Key(key)), matching: find.byType(InputDecorator))).height;
      expect(fieldHeight('drop'), closeTo(fieldHeight('text'), 1));
      expect(find.text('Pick a class'), findsOneWidget);
      await tester.tap(find.byKey(const Key('off')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Section A'), findsNothing);
    });
  });

  group('AppDateField', () {
    testWidgets('shows the date text and opens the picker on tap', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Scaffold(
          body: AppDateField(label: 'Date of birth', valueText: '12 Mar 2013', onTap: () => taps += 1),
        ),
      );
      expect(find.text('12 Mar 2013'), findsOneWidget);
      await tester.tap(find.text('12 Mar 2013'));
      expect(taps, 1);
    });

    testWidgets('speaks as a button with its label and value, flagged required, with the error as the hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        Scaffold(
          body: AppDateField(
            label: 'Date of birth',
            valueText: '12 Mar 2013',
            required: true,
            requiredLabel: 'Required',
            error: 'Pick a date before today',
            onTap: () {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Date of birth')),
        matchesSemantics(
          label: 'Date of birth',
          value: '12 Mar 2013',
          hint: 'Required. Pick a date before today',
          isButton: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasRequiredState: true,
          isRequired: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a keyboard user can focus it, sees the accent focus border, and opens it with Enter', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Scaffold(
          body: AppDateField(label: 'Date', valueText: '12 Mar 2013', onTap: () => taps += 1),
        ),
      );
      InputDecorator decorator() => tester.widget<InputDecorator>(find.byType(InputDecorator));
      expect(decorator().isFocused, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(decorator().isFocused, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('while pressed it shows a hover tint, and without onTap it is disabled', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: AppDateField(label: 'Date', valueText: '12 Mar 2013', onTap: () {}),
        ),
      );
      final gesture = await tester.startGesture(tester.getCenter(find.text('12 Mar 2013')));
      await tester.pump();
      expect(tester.widget<InputDecorator>(find.byType(InputDecorator)).isHovering, isTrue);
      await gesture.up();
      await tester.pump();
      expect(tester.widget<InputDecorator>(find.byType(InputDecorator)).isHovering, isFalse);

      await tester.pumpApp(
        const Scaffold(
          body: AppDateField(label: 'Date', valueText: '', onTap: null),
        ),
      );
      expect(tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration.enabled, isFalse);
    });
  });

  group('AppSearchField', () {
    testWidgets('the clear button appears when there is text and empties the box', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var last = 'x';
      await tester.pumpApp(
        Scaffold(
          body: AppSearchField(
            controller: controller,
            hint: 'Search',
            clearTooltip: 'Clear',
            onChanged: (v) => last = v,
          ),
        ),
      );
      expect(find.byTooltip('Clear'), findsNothing);
      await tester.enterText(find.byType(TextField), 'asha');
      await tester.pump();
      expect(find.byTooltip('Clear'), findsOneWidget);
      expect(tester.getSize(find.byTooltip('Clear')).shortestSide, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(last, isEmpty);
      expect(find.byTooltip('Clear'), findsNothing);
    });
  });
}
