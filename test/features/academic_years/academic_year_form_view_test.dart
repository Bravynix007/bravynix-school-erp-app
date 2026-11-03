import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/bloc/academic_year_form_bloc.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/view/academic_year_form_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';

class _MockFormBloc extends MockBloc<AcademicYearFormEvent, AcademicYearFormState> implements AcademicYearFormBloc;

ApiFailure _failure(int status, String code, {List<FieldError> fields = const []}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words', fieldErrors: fields);

void main() {
  late _MockFormBloc bloc;
  setUpAll(
    () => registerFallbackValue(
      const AcademicYearFormSubmitted(AcademicYearFields(name: '', startDate: '', endDate: '')),
    ),
  );
  setUp(() => bloc = _MockFormBloc());

  Future<void> pump(
    WidgetTester tester,
    AcademicYearFormState state, {
    AcademicYear? year,
    double textScale = 1,
    Size size = const Size(400, 1200),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<AcademicYearFormBloc>.value(
        value: bloc,
        child: AcademicYearFormView(year: year),
      ),
      textScale: textScale,
      size: size,
    );
  }

  Finder nameField() =>
      find.descendant(of: find.byKey(const Key('academicYearForm.name')), matching: find.byType(TextField));

  AcademicYearFormSubmitted submitted() =>
      verify(() => bloc.add(captureAny())).captured.single as AcademicYearFormSubmitted;

  testWidgets('an empty form to add: no dates chosen yet', (tester) async {
    await pump(tester, const AcademicYearFormEditing());
    expect(find.text('Add academic year'), findsOneWidget);
    expect(tester.widget<TextField>(nameField()).controller!.text, isEmpty);
    expect(find.text('For example 2026-2027'), findsOneWidget);
    expect(find.textContaining('Starts on', findRichText: true), findsOneWidget);
    expect(find.textContaining('Ends on', findRichText: true), findsOneWidget);
  });

  testWidgets('an edit starts from the year and its dates', (tester) async {
    await pump(tester, const AcademicYearFormEditing(), year: earlierYear);
    expect(find.text('Edit academic year'), findsOneWidget);
    expect(tester.widget<TextField>(nameField()).controller!.text, '2025-2026');
    expect(find.text('01-06-2025'), findsOneWidget);
    expect(find.text('31-03-2026'), findsOneWidget);
  });

  testWidgets('Save sends what is typed and the days picked on the calendar', (tester) async {
    await pump(tester, const AcademicYearFormEditing(), year: earlierYear);
    await tester.enterText(nameField(), '  2025-26  ');
    await tester.tap(find.byKey(const Key('academicYearForm.start')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('15-06-2025'), findsOneWidget);
    await tester.tap(find.text('Save'));
    expect(
      submitted().fields,
      const AcademicYearFields(name: '  2025-26  ', startDate: '2025-06-15', endDate: '2026-03-31'),
    );
  });

  testWidgets('a calendar that is cancelled changes nothing', (tester) async {
    await pump(tester, const AcademicYearFormEditing(), year: earlierYear);
    await tester.tap(find.byKey(const Key('academicYearForm.end')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Cancel')));
    await tester.pumpAndSettle();
    expect(find.text('31-03-2026'), findsOneWidget);
  });

  testWidgets('while saving, Save does nothing', (tester) async {
    await pump(tester, const AcademicYearFormEditing(saving: true), year: earlierYear);
    final save = find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(FilledButton));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
  });

  testWidgets('shows a refused field under that field', (tester) async {
    await pump(
      tester,
      AcademicYearFormEditing(
        failure: _failure(
          400,
          'VALIDATION_FAILED',
          fields: const [FieldError(field: 'name', code: 'REQUIRED', message: 'Name is required')],
        ),
      ),
    );
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.byKey(const Key('academicYearForm.error')), findsNothing);
  });

  testWidgets('says a taken name under the Name field, in the app words', (tester) async {
    await pump(
      tester,
      AcademicYearFormEditing(
        failure: _failure(
          409,
          'DUPLICATE',
          fields: const [FieldError(field: 'name', code: 'DUPLICATE', message: 'x')],
        ),
      ),
    );
    expect(find.text('Another academic year of this Institution has this name.'), findsOneWidget);
    expect(find.byKey(const Key('academicYearForm.error')), findsNothing);
  });

  testWidgets('says a refusal of a field the form does not show above it', (tester) async {
    await pump(
      tester,
      AcademicYearFormEditing(
        failure: _failure(
          400,
          'VALIDATION_FAILED',
          fields: const [FieldError(field: 'institutionId', code: 'INVALID', message: 'm')],
        ),
      ),
    );
    expect(find.byKey(const Key('academicYearForm.error')), findsOneWidget);
    expect(find.text('Check the fields marked in red.'), findsOneWidget);
  });

  testWidgets('offers Back to the list only after a version conflict', (tester) async {
    await pump(tester, AcademicYearFormEditing(failure: _failure(409, 'YEAR_OVERLAP')), year: earlierYear);
    expect(find.byKey(const Key('academicYearForm.backToList')), findsNothing);
  });

  testWidgets('Back to the list after a version conflict closes with true, so the list is read again', (tester) async {
    when(() => bloc.state).thenReturn(AcademicYearFormEditing(failure: _failure(409, 'VERSION_CONFLICT')));
    bool? closedWith;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => closedWith = await context.push<bool>('/form'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/form',
          builder: (_, _) => BlocProvider<AcademicYearFormBloc>.value(
            value: bloc,
            child: const AcademicYearFormView(year: earlierYear),
          ),
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
    await tester.tap(find.byKey(const Key('academicYearForm.backToList')));
    await tester.pumpAndSettle();
    expect(closedWith, isTrue);
  });

  for (final (status, code, text) in [
    (409, 'YEAR_OVERLAP', 'These dates overlap another academic year of this Institution.'),
    (409, 'VERSION_CONFLICT', 'Someone else changed this. Your changes were not saved.'),
  ]) {
    testWidgets('says $code in words above the form', (tester) async {
      await pump(tester, AcademicYearFormEditing(failure: _failure(status, code)), year: earlierYear);
      expect(find.byKey(const Key('academicYearForm.error')), findsOneWidget);
      expect(find.text(text), findsOneWidget);
    });
  }

  testWidgets('closes with true and says so once saved', (tester) async {
    whenListen(
      bloc,
      Stream.value(const AcademicYearFormSaved(earlierYear)),
      initialState: const AcademicYearFormEditing(saving: true),
    );
    bool? closedWith;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => closedWith = await context.push<bool>('/form'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/form',
          builder: (_, _) => BlocProvider<AcademicYearFormBloc>.value(value: bloc, child: const AcademicYearFormView()),
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
    expect(closedWith, isTrue);
    expect(find.text('Academic year saved'), findsOneWidget);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(
      tester,
      AcademicYearFormEditing(failure: _failure(409, 'YEAR_OVERLAP')),
      year: earlierYear,
      textScale: 2,
      size: const Size(320, 1600),
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
