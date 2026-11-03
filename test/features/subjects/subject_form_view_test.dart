import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/bloc/subject_form_bloc.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/view/subject_form_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/subjects.dart';

class _MockFormBloc extends MockBloc<SubjectFormEvent, SubjectFormState> implements SubjectFormBloc;

ApiFailure _failure(int status, String code, {List<FieldError> fields = const []}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words', fieldErrors: fields);

void main() {
  late _MockFormBloc bloc;
  setUpAll(() => registerFallbackValue(const SubjectFormSubmitted(SubjectFields(name: '', code: ''))));
  setUp(() => bloc = _MockFormBloc());

  Future<void> pump(
    WidgetTester tester,
    SubjectFormState state, {
    Subject? subject,
    double textScale = 1,
    Size size = const Size(400, 1200),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<SubjectFormBloc>.value(
        value: bloc,
        child: SubjectFormView(subject: subject),
      ),
      textScale: textScale,
      size: size,
    );
  }

  Finder field(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));
  String textOf(WidgetTester tester, String key) => tester.widget<TextField>(field(key)).controller!.text;

  testWidgets('an empty form to add', (tester) async {
    await pump(tester, const SubjectFormEditing());
    expect(find.text('Add subject'), findsOneWidget);
    expect(textOf(tester, 'subjectForm.name'), isEmpty);
    expect(textOf(tester, 'subjectForm.code'), isEmpty);
    expect(find.text('Optional, like MATH'), findsOneWidget);
  });

  testWidgets('an edit starts from the subject', (tester) async {
    await pump(tester, const SubjectFormEditing(), subject: maths);
    expect(find.text('Edit subject'), findsOneWidget);
    expect(textOf(tester, 'subjectForm.name'), 'Mathematics');
    expect(textOf(tester, 'subjectForm.code'), 'MATH');
  });

  testWidgets('a subject without a code starts with an empty one', (tester) async {
    await pump(tester, const SubjectFormEditing(), subject: art);
    expect(textOf(tester, 'subjectForm.code'), isEmpty);
  });

  testWidgets('Save sends what is typed', (tester) async {
    await pump(tester, const SubjectFormEditing(), subject: maths);
    await tester.enterText(field('subjectForm.name'), 'Maths');
    await tester.enterText(field('subjectForm.code'), '');
    await tester.tap(find.text('Save'));
    final event = verify(() => bloc.add(captureAny())).captured.single as SubjectFormSubmitted;
    expect(event.fields, const SubjectFields(name: 'Maths', code: ''));
  });

  testWidgets('while saving, Save does nothing', (tester) async {
    await pump(tester, const SubjectFormEditing(saving: true), subject: maths);
    final save = find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(FilledButton));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
  });

  testWidgets('says a taken name and a taken code under their own fields, in the app words', (tester) async {
    await pump(
      tester,
      SubjectFormEditing(
        failure: _failure(
          409,
          'DUPLICATE',
          fields: const [
            FieldError(field: 'name', code: 'DUPLICATE', message: 'x'),
            FieldError(field: 'code', code: 'DUPLICATE', message: 'x'),
          ],
        ),
      ),
    );
    expect(find.text('Another subject has this name.'), findsOneWidget);
    expect(find.text('Another subject has this code.'), findsOneWidget);
    expect(find.byKey(const Key('subjectForm.error')), findsNothing);
  });

  testWidgets('shows a refused field under that field', (tester) async {
    await pump(
      tester,
      SubjectFormEditing(
        failure: _failure(
          400,
          'VALIDATION_FAILED',
          fields: const [FieldError(field: 'name', code: 'REQUIRED', message: 'Name is required')],
        ),
      ),
    );
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.byKey(const Key('subjectForm.error')), findsNothing);
  });

  testWidgets('says a refusal that names no field of the form above it', (tester) async {
    await pump(
      tester,
      SubjectFormEditing(
        failure: _failure(
          400,
          'VALIDATION_FAILED',
          fields: const [FieldError(field: 'x', code: 'X', message: 'm')],
        ),
      ),
    );
    expect(find.byKey(const Key('subjectForm.error')), findsOneWidget);
  });

  for (final (status, code, text) in [
    (409, 'VERSION_CONFLICT', 'Someone else changed this. Your changes were not saved.'),
    (404, 'NOT_FOUND', 'This subject could not be found. It may have been deactivated.'),
    (403, 'FORBIDDEN', "You don't have access to this."),
  ]) {
    testWidgets('says $code in words above the form', (tester) async {
      await pump(tester, SubjectFormEditing(failure: _failure(status, code)), subject: maths);
      expect(find.byKey(const Key('subjectForm.error')), findsOneWidget);
      expect(find.text(text), findsOneWidget);
    });
  }

  testWidgets('closes with true and says so once saved', (tester) async {
    whenListen(bloc, Stream.value(const SubjectFormSaved(maths)), initialState: const SubjectFormEditing(saving: true));
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
          builder: (_, _) => BlocProvider<SubjectFormBloc>.value(value: bloc, child: const SubjectFormView()),
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
    expect(find.text('Subject saved'), findsOneWidget);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(
      tester,
      SubjectFormEditing(failure: _failure(409, 'VERSION_CONFLICT')),
      subject: maths,
      textScale: 2,
      size: const Size(320, 1600),
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
