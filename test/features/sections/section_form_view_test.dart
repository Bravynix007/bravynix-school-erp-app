import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';
import 'package:bravynix_school_erp/features/sections/presentation/bloc/section_form_bloc.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/section_form_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/leaving_a_form.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/sections.dart';

class _MockFormBloc extends MockBloc<SectionFormEvent, SectionFormState> implements SectionFormBloc;

ApiFailure _failure(int status, String code, {List<FieldError> fields = const []}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words', fieldErrors: fields);

const _adding = SectionFormEditing(choices: [sectionAEntry, sectionBEntry]);

void main() {
  late _MockFormBloc bloc;
  setUpAll(() => registerFallbackValue(const SectionFormSubmitted(SectionFields(displayName: ''))));
  setUp(() => bloc = _MockFormBloc());

  Future<void> pump(
    WidgetTester tester,
    SectionFormState state, {
    Section? section,
    double textScale = 1,
    Size size = const Size(400, 2000),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<SectionFormBloc>.value(
        value: bloc,
        child: SectionFormView(section: section),
      ),
      textScale: textScale,
      size: size,
    );
  }

  Finder field(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));
  String textOf(WidgetTester tester, String key) => tester.widget<TextField>(field(key)).controller!.text;
  SectionFormSubmitted submitted() => verify(() => bloc.add(captureAny())).captured.single as SectionFormSubmitted;

  testWidgets('shows a placeholder while what can be added is read', (tester) async {
    await pump(tester, const SectionFormLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('says why it failed, and reads again on Try again', (tester) async {
    await pump(tester, const SectionFormFailed(ApiFailure.network()));
    expect(find.byKey(const Key('sectionForm.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const SectionFormStarted())).called(1);
  });

  testWidgets('adding: the sections still to add are listed, with a hint for the name and a warning for capacity', (
    tester,
  ) async {
    await pump(tester, _adding);
    expect(find.text('Add section'), findsOneWidget);
    expect(find.text('Section A'), findsOneWidget);
    expect(find.text('Section B'), findsOneWidget);
    expect(find.text('Section name'), findsOneWidget);
    expect(find.text('Optional. A warning, not a limit'), findsOneWidget);
  });

  testWidgets('adding with no section chosen asks for one and sends nothing', (tester) async {
    await pump(tester, _adding);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Choose a section'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('Save sends the section chosen with the name and capacity typed', (tester) async {
    await pump(tester, _adding);
    await tester.tap(find.byKey(const ValueKey('sectionForm.choice.s2')));
    await tester.enterText(field('sectionForm.displayName'), 'Blue');
    await tester.enterText(field('sectionForm.capacity'), '35');
    await tester.tap(find.text('Save'));
    expect(
      submitted().fields,
      const SectionFields(predefinedSectionId: 's2', displayName: 'Blue', capacity: 35),
    );
  });

  testWidgets('a capacity left empty is sent as none', (tester) async {
    await pump(tester, _adding);
    await tester.tap(find.byKey(const ValueKey('sectionForm.choice.s1')));
    await tester.tap(find.text('Save'));
    expect(submitted().fields, const SectionFields(predefinedSectionId: 's1', displayName: ''));
  });

  testWidgets('the capacity takes digits only', (tester) async {
    await pump(tester, _adding);
    await tester.enterText(field('sectionForm.capacity'), '4a0-');
    expect(textOf(tester, 'sectionForm.capacity'), '40');
  });

  for (final value in ['0', '32768']) {
    testWidgets('a capacity of $value is refused on the form, before anything is sent', (tester) async {
      await pump(tester, _adding);
      await tester.tap(find.byKey(const ValueKey('sectionForm.choice.s1')));
      await tester.enterText(field('sectionForm.capacity'), value);
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('Use 1 to 32767.'), findsOneWidget);
      verifyNever(() => bloc.add(any()));
      // Typing again takes the message away.
      await tester.enterText(field('sectionForm.capacity'), '40');
      await tester.pump();
      expect(find.text('Use 1 to 32767.'), findsNothing);
    });
  }

  testWidgets('the largest capacity is accepted', (tester) async {
    await pump(tester, _adding);
    await tester.tap(find.byKey(const ValueKey('sectionForm.choice.s1')));
    await tester.enterText(field('sectionForm.capacity'), '32767');
    await tester.tap(find.text('Save'));
    expect(submitted().fields.capacity, 32767);
  });

  testWidgets('says when the class has every section already', (tester) async {
    await pump(tester, const SectionFormEditing());
    expect(find.text('Every predefined section is already added to this class.'), findsOneWidget);
  });

  testWidgets('editing starts from the section, which is shown but cannot be changed', (tester) async {
    await pump(tester, const SectionFormEditing(), section: sectionA);
    expect(find.text('Edit section'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);
    expect(find.text('Section A'), findsNWidgets(2)); // the section shown, and the name in its field
    expect(textOf(tester, 'sectionForm.displayName'), 'Section A');
    expect(textOf(tester, 'sectionForm.capacity'), '40');
    expect(find.byKey(const ValueKey('sectionForm.choice.s1')), findsNothing);
  });

  testWidgets('editing Save sends the name and capacity, with no section chosen, and an emptied capacity as none', (
    tester,
  ) async {
    await pump(tester, const SectionFormEditing(), section: sectionA);
    await tester.enterText(field('sectionForm.displayName'), 'Blue');
    await tester.enterText(field('sectionForm.capacity'), '');
    await tester.tap(find.text('Save'));
    expect(submitted().fields, const SectionFields(displayName: 'Blue'));
  });

  testWidgets('while saving, Save does nothing', (tester) async {
    await pump(tester, const SectionFormEditing(saving: true), section: sectionA);
    final save = find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(FilledButton));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
  });

  testWidgets('says a taken name and a taken section under their own fields, in the app words', (tester) async {
    await pump(
      tester,
      SectionFormEditing(
        choices: const [sectionAEntry],
        failure: _failure(
          409,
          'DUPLICATE',
          fields: const [
            FieldError(field: 'displayName', code: 'DUPLICATE', message: 'x'),
            FieldError(field: 'predefinedSectionId', code: 'DUPLICATE', message: 'x'),
          ],
        ),
      ),
    );
    expect(find.text('Another section of this class has this name.'), findsOneWidget);
    expect(find.text('This section is already added to this class.'), findsOneWidget);
    expect(find.byKey(const Key('sectionForm.error')), findsNothing);
  });

  testWidgets('says a refused capacity under Capacity, in the server words, with no banner above', (tester) async {
    await pump(
      tester,
      SectionFormEditing(
        choices: const [sectionAEntry],
        failure: _failure(
          400,
          'VALIDATION_FAILED',
          fields: const [FieldError(field: 'capacity', code: 'OUT_OF_RANGE', message: 'Capacity is too large')],
        ),
      ),
    );
    expect(find.text('Capacity is too large'), findsOneWidget);
    expect(find.byKey(const Key('sectionForm.error')), findsNothing);
  });

  testWidgets('says a refusal of a field the form does not show above it', (tester) async {
    await pump(
      tester,
      SectionFormEditing(
        choices: const [sectionAEntry],
        failure: _failure(
          400,
          'VALIDATION_FAILED',
          fields: const [FieldError(field: 'classId', code: 'INVALID', message: 'm')],
        ),
      ),
    );
    expect(find.byKey(const Key('sectionForm.error')), findsOneWidget);
  });

  for (final (status, code, text) in [
    (409, 'DUPLICATE', 'Another section of this class already has this name.'),
    (404, 'NOT_FOUND', 'This section could not be found. It may have been deactivated.'),
    (403, 'FORBIDDEN', "You don't have access to this."),
  ]) {
    testWidgets('says $code in words above the form', (tester) async {
      await pump(tester, SectionFormEditing(failure: _failure(status, code)), section: sectionA);
      expect(find.byKey(const Key('sectionForm.error')), findsOneWidget);
      expect(find.text(text), findsOneWidget);
      expect(find.byKey(const Key('sectionForm.backToList')), findsNothing);
    });
  }

  testWidgets('offers Back to the list after a version conflict', (tester) async {
    await pump(tester, SectionFormEditing(failure: _failure(409, 'VERSION_CONFLICT')), section: sectionA);
    expect(find.text('Someone else changed this. Your changes were not saved.'), findsOneWidget);
    expect(find.byKey(const Key('sectionForm.backToList')), findsOneWidget);
  });

  leavingAFormTests(
    backToList: const Key('sectionForm.backToList'),
    setFailure: (failure) => when(() => bloc.state).thenReturn(SectionFormEditing(failure: failure)),
    form: () => BlocProvider<SectionFormBloc>.value(
      value: bloc,
      child: const SectionFormView(section: sectionA),
    ),
  );

  Future<void> openForm(WidgetTester tester, Widget form) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(onPressed: () => context.push<bool>('/form'), child: const Text('open')),
          ),
        ),
        GoRoute(
          path: '/form',
          builder: (_, _) => BlocProvider<SectionFormBloc>.value(value: bloc, child: form),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('closes with true and says so once saved', (tester) async {
    whenListen(
      bloc,
      Stream.value(const SectionFormSaved(sectionA)),
      initialState: const SectionFormEditing(saving: true),
    );
    await openForm(tester, const SectionFormView());
    expect(find.text('Section saved'), findsOneWidget);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, _adding, textScale: 2, size: const Size(320, 3000));
    await tester.enterText(field('sectionForm.capacity'), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
