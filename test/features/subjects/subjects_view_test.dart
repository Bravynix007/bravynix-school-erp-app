import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/view/subjects_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/subjects.dart';

class _MockSubjectsBloc extends MockBloc<SubjectsEvent, SubjectsState> implements SubjectsBloc;

void main() {
  late _MockSubjectsBloc bloc;
  setUpAll(() {
    registerFallbackValue(const SubjectsRequested());
    registerFallbackValue(const SubjectDeactivated(maths));
  });
  setUp(() => bloc = _MockSubjectsBloc());

  Future<void> pump(
    WidgetTester tester,
    SubjectsState state, {
    double textScale = 1,
    Size size = const Size(400, 1200),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<SubjectsBloc>.value(value: bloc, child: const SubjectsView()),
      textScale: textScale,
      size: size,
    );
  }

  /// The list on a router, with the form route answering [saved] when it closes, and recording what it was given.
  Future<List<Object?>> pumpWithForm(WidgetTester tester, SubjectsState state, {required bool saved}) async {
    when(() => bloc.state).thenReturn(state);
    final opened = <Object?>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => BlocProvider<SubjectsBloc>.value(value: bloc, child: const SubjectsView()),
        ),
        GoRoute(
          path: AppRoutes.subjectForm,
          builder: (context, routeState) {
            opened.add(routeState.extra);
            return TextButton(onPressed: () => context.pop(saved), child: const Text('form'));
          },
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
    return opened;
  }

  testWidgets('lists each subject, with its code when it has one', (tester) async {
    await pump(tester, const SubjectsLoaded([maths, art]));
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('MATH'), findsOneWidget);
    expect(find.text('Art'), findsOneWidget);
    expect(find.byKey(const ValueKey('subject.edit.u2')), findsOneWidget);
    expect(find.byKey(const ValueKey('subject.deactivate.u2')), findsOneWidget);
  });

  testWidgets('Deactivate asks first, and does nothing when cancelled', (tester) async {
    await pump(tester, const SubjectsLoaded([maths, art]));
    await tester.tap(find.byKey(const ValueKey('subject.deactivate.u1')));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate Mathematics?'), findsOneWidget);
    expect(find.text('It leaves the list and its name and code are free again. Nothing is deleted.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any(that: isA<SubjectDeactivated>())));
  });

  testWidgets('Deactivate goes ahead once confirmed', (tester) async {
    await pump(tester, const SubjectsLoaded([maths, art]));
    await tester.tap(find.byKey(const ValueKey('subject.deactivate.u1')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Deactivate')));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const SubjectDeactivated(maths))).called(1);
  });

  testWidgets('while a deactivation is on its way, that subject cannot be changed again', (tester) async {
    await pump(tester, const SubjectsLoaded([maths, art], busyId: 'u1'));
    Finder button(String key) =>
        find.descendant(of: find.byKey(ValueKey(key)), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    expect(tester.widget<ButtonStyleButton>(button('subject.edit.u1')).onPressed, isNull);
    expect(tester.widget<ButtonStyleButton>(button('subject.deactivate.u1')).onPressed, isNull);
    // No other card starts a change meanwhile.
    expect(tester.widget<ButtonStyleButton>(button('subject.edit.u2')).onPressed, isNull);
  });

  testWidgets('says why a deactivation was refused, above the list', (tester) async {
    await pump(
      tester,
      const SubjectsLoaded([maths], actionFailure: ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')),
    );
    expect(find.byKey(const Key('subjects.actionFailed')), findsOneWidget);
    expect(find.text('This subject could not be found. It may have been deactivated.'), findsOneWidget);
  });

  testWidgets('says which subject was deactivated', (tester) async {
    whenListen(
      bloc,
      Stream.value(const SubjectsLoaded([art], deactivated: maths)),
      initialState: const SubjectsLoaded([maths, art]),
    );
    await tester.pumpAppScaled(
      BlocProvider<SubjectsBloc>.value(value: bloc, child: const SubjectsView()),
      size: const Size(400, 1200),
    );
    await tester.pump();
    expect(find.text('Mathematics deactivated'), findsOneWidget);
  });

  testWidgets('invites the first subject when there is none', (tester) async {
    await pump(tester, const SubjectsLoaded([]));
    expect(find.text('No subjects yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add subject'), findsOneWidget);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const SubjectsLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and loads again on Try again', (tester) async {
    await pump(tester, const SubjectsFailed(ApiFailure.network()));
    expect(find.byKey(const Key('subjects.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const SubjectsRequested())).called(1);
  });

  testWidgets('says a role that may not see subjects has no access', (tester) async {
    await pump(tester, const SubjectsFailed(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
    expect(find.byKey(const Key('subjects.forbidden')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  group('the form', () {
    testWidgets('Add opens it with no subject, and reads the list again once saved', (tester) async {
      final opened = await pumpWithForm(tester, const SubjectsLoaded([maths]), saved: true);
      await tester.tap(find.byKey(const Key('subjects.add')));
      await tester.pumpAndSettle();
      expect(opened.single, isNull);
      verifyNever(() => bloc.add(const SubjectsRequested()));
      await tester.tap(find.text('form'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const SubjectsRequested())).called(1);
    });

    testWidgets('the empty list opens it too', (tester) async {
      final opened = await pumpWithForm(tester, const SubjectsLoaded([]), saved: false);
      await tester.tap(find.widgetWithText(FilledButton, 'Add subject'));
      await tester.pumpAndSettle();
      expect(opened.single, isNull);
    });

    testWidgets('Edit hands the subject over, and leaves the list alone when the form was cancelled', (tester) async {
      final opened = await pumpWithForm(tester, const SubjectsLoaded([maths, art]), saved: false);
      await tester.tap(find.byKey(const ValueKey('subject.edit.u2')));
      await tester.pumpAndSettle();
      expect(opened.single, isA<Subject>().having((subject) => subject.id, 'id', 'u2'));
      await tester.tap(find.text('form'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(const SubjectsRequested()));
    });
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(
      tester,
      const SubjectsLoaded([
        Subject(id: 'u3', name: 'Environmental Studies and Sciences', code: 'ENVSTUDIES', version: 1),
        art,
      ]),
      textScale: 2,
      size: const Size(320, 1600),
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
