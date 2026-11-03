import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/classes/presentation/bloc/class_form_bloc.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_form_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/classes.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';

class _MockFormBloc extends MockBloc<ClassFormEvent, ClassFormState> implements ClassFormBloc;

ApiFailure _failure(int status, String code, {List<FieldError> fields = const []}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words', fieldErrors: fields);

const _adding = ClassFormEditing(choices: [class1Choice, class2Choice, pucChoice]);

void main() {
  late _MockFormBloc bloc;
  setUpAll(
    () => registerFallbackValue(const ClassFormSubmitted(ClassFields(streamName: '', displayName: '', code: ''))),
  );
  setUp(() => bloc = _MockFormBloc());

  Future<void> pump(
    WidgetTester tester,
    ClassFormState state, {
    SchoolClass? schoolClass,
    double textScale = 1,
    Size size = const Size(400, 2000),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<ClassFormBloc>.value(
        value: bloc,
        child: ClassFormView(schoolClass: schoolClass),
      ),
      textScale: textScale,
      size: size,
    );
  }

  Finder field(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));
  String textOf(WidgetTester tester, String key) => tester.widget<TextField>(field(key)).controller!.text;
  ClassFormSubmitted submitted() => verify(() => bloc.add(captureAny())).captured.single as ClassFormSubmitted;

  testWidgets('shows a placeholder while what can be added is read', (tester) async {
    await pump(tester, const ClassFormLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('says why it failed, and reads again on Try again', (tester) async {
    await pump(tester, const ClassFormFailed(ApiFailure.network()));
    expect(find.byKey(const Key('classForm.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const ClassFormStarted())).called(1);
  });

  testWidgets('adding: the classes of the offered categories are listed under their categories', (tester) async {
    await pump(tester, _adding);
    expect(find.text('Add class'), findsOneWidget);
    expect(find.text('Lower Primary'), findsOneWidget);
    expect(find.text('Pre-University'), findsOneWidget);
    expect(find.text('Class 1'), findsOneWidget);
    expect(find.text('PUC 1st Year'), findsOneWidget);
    expect(find.byKey(const Key('classForm.stream')), findsNothing);
    expect(find.text('Class name'), findsOneWidget);
  });

  testWidgets('adding with no class chosen asks for one and sends nothing', (tester) async {
    await pump(tester, _adding);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Choose a class'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('Save sends the class chosen with the name and code typed', (tester) async {
    await pump(tester, _adding);
    await tester.tap(find.byKey(const ValueKey('classForm.choice.p2')));
    await tester.enterText(field('classForm.displayName'), 'Second');
    await tester.enterText(field('classForm.code'), 'TWO');
    await tester.tap(find.text('Save'));
    expect(
      submitted().fields,
      const ClassFields(choice: class2Choice, streamName: '', displayName: 'Second', code: 'TWO'),
    );
  });

  testWidgets('a Pre-University class asks for its stream, and no other class does', (tester) async {
    await pump(tester, _adding);
    await tester.tap(find.byKey(const ValueKey('classForm.choice.p9')));
    await tester.pump();
    expect(find.byKey(const Key('classForm.stream')), findsOneWidget);
    await tester.enterText(field('classForm.stream'), 'PCMC');
    await tester.tap(find.text('Save'));
    expect(submitted().fields.streamName, 'PCMC');
    await tester.tap(find.byKey(const ValueKey('classForm.choice.p1')));
    await tester.pump();
    expect(find.byKey(const Key('classForm.stream')), findsNothing);
  });

  testWidgets('says when the Institution has no class left to add', (tester) async {
    await pump(tester, const ClassFormEditing());
    expect(
      find.text('Every class of the categories this Institution offers is already added, or needs a stream.'),
      findsOneWidget,
    );
  });

  testWidgets('editing starts from the class, which is shown but cannot be changed', (tester) async {
    await pump(tester, const ClassFormEditing(), schoolClass: pucClass);
    expect(find.text('Edit class'), findsOneWidget);
    expect(find.text('Class'), findsOneWidget);
    expect(find.text('PUC 1st Year PCMC'), findsNWidgets(2)); // the class shown, and the name in its field
    expect(textOf(tester, 'classForm.displayName'), 'PUC 1st Year PCMC');
    expect(find.text('Pre-University'), findsOneWidget);
    expect(find.byKey(const Key('classForm.stream')), findsNothing);
  });

  testWidgets('editing Save sends the name and code, with no class chosen', (tester) async {
    await pump(tester, const ClassFormEditing(), schoolClass: class1);
    expect(textOf(tester, 'classForm.code'), 'ONE');
    await tester.enterText(field('classForm.displayName'), 'One');
    await tester.enterText(field('classForm.code'), '');
    await tester.tap(find.text('Save'));
    expect(submitted().fields, const ClassFields(streamName: '', displayName: 'One', code: ''));
  });

  testWidgets('while saving, Save does nothing', (tester) async {
    await pump(tester, const ClassFormEditing(saving: true), schoolClass: class1);
    final save = find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(FilledButton));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
  });

  testWidgets('says a taken name and a taken class under their own fields, in the app words', (tester) async {
    await pump(
      tester,
      ClassFormEditing(
        choices: const [class1Choice, pucChoice],
        failure: _failure(
          409,
          'DUPLICATE',
          fields: const [
            FieldError(field: 'displayName', code: 'DUPLICATE', message: 'x'),
            FieldError(field: 'predefinedClassId', code: 'DUPLICATE', message: 'x'),
          ],
        ),
      ),
    );
    expect(find.text('Another class of this Institution has this name.'), findsOneWidget);
    expect(find.text('This class is already added to this Institution.'), findsOneWidget);
    expect(find.byKey(const Key('classForm.error')), findsNothing);
  });

  testWidgets('says a refusal of a field the form does not show above it', (tester) async {
    await pump(
      tester,
      ClassFormEditing(
        choices: const [class1Choice],
        failure: _failure(
          400,
          'VALIDATION_FAILED',
          fields: const [FieldError(field: 'institutionId', code: 'INVALID', message: 'm')],
        ),
      ),
    );
    expect(find.byKey(const Key('classForm.error')), findsOneWidget);
  });

  for (final (status, code, text) in [
    (409, 'DUPLICATE', 'Another class of this Institution already has this name or stream.'),
    (
      422,
      'CLASS_NOT_OFFERED',
      "This Institution does not offer this class's category. Tick the category on the Institution first.",
    ),
    (404, 'NOT_FOUND', 'This class could not be found. It may have been deactivated.'),
    (403, 'FORBIDDEN', "You don't have access to this."),
  ]) {
    testWidgets('says $code in words above the form', (tester) async {
      await pump(tester, ClassFormEditing(failure: _failure(status, code)), schoolClass: class1);
      expect(find.byKey(const Key('classForm.error')), findsOneWidget);
      expect(find.text(text), findsOneWidget);
      expect(find.byKey(const Key('classForm.backToList')), findsNothing);
    });
  }

  testWidgets('Back to the list after a version conflict closes with true, so the list is read again', (tester) async {
    when(() => bloc.state).thenReturn(ClassFormEditing(failure: _failure(409, 'VERSION_CONFLICT')));
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
          builder: (_, _) => BlocProvider<ClassFormBloc>.value(
            value: bloc,
            child: const ClassFormView(schoolClass: class1),
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
    await tester.tap(find.byKey(const Key('classForm.backToList')));
    await tester.pumpAndSettle();
    expect(closedWith, isTrue);
  });

  testWidgets('closes with true and says so once saved', (tester) async {
    whenListen(bloc, Stream.value(const ClassFormSaved(class1)), initialState: const ClassFormEditing(saving: true));
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
          builder: (_, _) => BlocProvider<ClassFormBloc>.value(value: bloc, child: const ClassFormView()),
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
    expect(find.text('Class saved'), findsOneWidget);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, _adding, textScale: 2, size: const Size(320, 3600));
    await tester.tap(find.byKey(const ValueKey('classForm.choice.p9')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
