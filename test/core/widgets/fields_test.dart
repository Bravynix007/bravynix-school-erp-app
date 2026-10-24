import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_date_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_search_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
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

    testWidgets('a required field shows a red star that screen readers do not read, and says "required" once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(const Scaffold(body: AppTextField(label: 'Name', required: true)));
      final star = tester.widget<Text>(
        find.byWidgetPredicate((w) => w is Text && (w.textSpan?.toPlainText() ?? '').contains('Name')),
      );
      expect(star.textSpan!.toPlainText(), 'Name *');
      expect(find.ancestor(of: find.byWidget(star), matching: find.byType(ExcludeSemantics)), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Name, required')), findsOneWidget);
      handle.dispose();
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

    testWidgets('the outline is the darker field colour, and lighter when disabled', (tester) async {
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
      final on =
          decorators[0].decoration.enabledBorder ??
          Theme.of(tester.element(find.byType(InputDecorator).first)).inputDecorationTheme.enabledBorder;
      expect((on as OutlineInputBorder?)?.borderSide.color, AppColors.fieldBorder);
    });
  });

  group('AppDropdownField', () {
    testWidgets('shows the chosen value and reports a new choice', (tester) async {
      String? value = 'A';
      await tester.pumpApp(
        StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: AppDropdownField<String>(
              label: 'Class',
              value: value,
              items: const [
                DropdownMenuItem(value: 'A', child: Text('Section A')),
                DropdownMenuItem(value: 'B', child: Text('Section B')),
              ],
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

    testWidgets('speaks as a button with its label and value', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        Scaffold(
          body: AppDateField(label: 'Date of birth', valueText: '12 Mar 2013', required: true, onTap: () {}),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Date of birth, required')),
        matchesSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          label: 'Date of birth, required',
          value: '12 Mar 2013',
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
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
