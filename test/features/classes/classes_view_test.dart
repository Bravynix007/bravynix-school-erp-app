import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_bulk_page.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_form_page.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/classes_page.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/sections_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/classes.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';

class _MockClassesBloc extends MockBloc<ListEvent, ListState<SchoolClass>> implements ClassesBloc;

void main() {
  late _MockClassesBloc bloc;
  setUpAll(() {
    registerFallbackValue(const ListRequested());
    registerFallbackValue(const ClassDeactivated(class1));
  });
  setUp(() {
    bloc = _MockClassesBloc();
    when(() => bloc.institutionId).thenReturn('i1');
  });

  Future<void> pump(
    WidgetTester tester,
    ListState<SchoolClass> state, {
    double textScale = 1,
    Size size = const Size(400, 1200),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<ClassesBloc>.value(value: bloc, child: const ClassesView()),
      textScale: textScale,
      size: size,
    );
  }

  /// The list on a router whose form and bulk routes answer [saved] when they close, recording what they were given.
  Future<List<Object?>> pumpWithForms(WidgetTester tester, ListState<SchoolClass> state, {required bool saved}) async {
    when(() => bloc.state).thenReturn(state);
    final opened = <Object?>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: BlocProvider<ClassesBloc>.value(value: bloc, child: const ClassesView()),
          ),
        ),
        for (final route in [AppRoutes.classForm, AppRoutes.classBulk, AppRoutes.classSections])
          GoRoute(
            path: route,
            builder: (context, routeState) {
              opened.add(routeState.extra);
              return TextButton(onPressed: () => context.pop(saved), child: Text('form $route'));
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

  testWidgets('lists each class with its category, sections and code', (tester) async {
    await pump(tester, const ListLoaded<SchoolClass>([class1, pucClass]));
    expect(find.text('Class 1'), findsOneWidget);
    expect(find.text('Lower Primary · 2 sections · ONE'), findsOneWidget);
    expect(find.text('PUC 1st Year PCMC'), findsOneWidget);
    expect(find.text('Pre-University · No sections'), findsOneWidget);
  });

  testWidgets('Deactivate asks first, and does nothing when cancelled', (tester) async {
    await pump(tester, const ListLoaded<SchoolClass>([class1]));
    await tester.tap(find.byKey(const ValueKey('class.deactivate.k1')));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate Class 1?'), findsOneWidget);
    expect(find.text('Its sections are deactivated with it. Nothing is deleted.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any(that: isA<ClassDeactivated>())));
  });

  testWidgets('Deactivate goes ahead once confirmed', (tester) async {
    await pump(tester, const ListLoaded<SchoolClass>([class1]));
    await tester.tap(find.byKey(const ValueKey('class.deactivate.k1')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Deactivate')));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const ClassDeactivated(class1))).called(1);
  });

  testWidgets('while a deactivation is on its way, no card starts another change', (tester) async {
    await pump(tester, const ListLoaded<SchoolClass>([class1, pucClass], busyId: 'k1'));
    Finder button(String key) =>
        find.descendant(of: find.byKey(ValueKey(key)), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    expect(tester.widget<ButtonStyleButton>(button('class.edit.k1')).onPressed, isNull);
    expect(tester.widget<ButtonStyleButton>(button('class.deactivate.k1')).onPressed, isNull);
    expect(tester.widget<ButtonStyleButton>(button('class.edit.k9')).onPressed, isNull);
  });

  testWidgets('says why a deactivation was refused, above the list', (tester) async {
    await pump(
      tester,
      const ListLoaded<SchoolClass>([
        class1,
      ], actionFailure: ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')),
    );
    expect(find.byKey(const Key('classes.actionFailed')), findsOneWidget);
    expect(find.text('This class could not be found. It may have been deactivated.'), findsOneWidget);
  });

  testWidgets('says which class was deactivated', (tester) async {
    whenListen(
      bloc,
      Stream.value(const ListLoaded<SchoolClass>([pucClass], changed: class1)),
      initialState: const ListLoaded<SchoolClass>([class1, pucClass]),
    );
    await tester.pumpAppScaled(
      Scaffold(
        body: BlocProvider<ClassesBloc>.value(value: bloc, child: const ClassesView()),
      ),
      size: const Size(400, 1200),
    );
    await tester.pump();
    expect(find.text('Class 1 deactivated'), findsOneWidget);
  });

  testWidgets('invites the first class when there is none', (tester) async {
    await pump(tester, const ListLoaded<SchoolClass>([]));
    expect(find.text('No classes yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add class'), findsOneWidget);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const ListLoading<SchoolClass>());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and loads again on Try again', (tester) async {
    await pump(tester, const ListFailed<SchoolClass>(ApiFailure.network()));
    expect(find.byKey(const Key('classes.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const ListRequested())).called(1);
  });

  testWidgets('says a role that may not see classes has no access', (tester) async {
    await pump(tester, const ListFailed<SchoolClass>(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
    expect(find.byKey(const Key('classes.forbidden')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  group('the forms', () {
    testWidgets('Add class opens the form for this Institution with no class, and reads the list again once saved', (
      tester,
    ) async {
      final opened = await pumpWithForms(tester, const ListLoaded<SchoolClass>([class1]), saved: true);
      await tester.tap(find.byKey(const Key('classes.add')));
      await tester.pumpAndSettle();
      final args = opened.single! as ClassFormArgs;
      expect(args.institutionId, 'i1');
      expect(args.schoolClass, isNull);
      verifyNever(() => bloc.add(const ListRequested()));
      await tester.tap(find.text('form ${AppRoutes.classForm}'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const ListRequested())).called(1);
    });

    testWidgets('the empty list opens it too', (tester) async {
      final opened = await pumpWithForms(tester, const ListLoaded<SchoolClass>([]), saved: false);
      await tester.tap(find.widgetWithText(FilledButton, 'Add class'));
      await tester.pumpAndSettle();
      expect((opened.single! as ClassFormArgs).schoolClass, isNull);
    });

    testWidgets('Edit hands the class over, and leaves the list alone when the form was cancelled', (tester) async {
      final opened = await pumpWithForms(tester, const ListLoaded<SchoolClass>([class1, pucClass]), saved: false);
      await tester.tap(find.byKey(const ValueKey('class.edit.k9')));
      await tester.pumpAndSettle();
      expect((opened.single! as ClassFormArgs).schoolClass, pucClass);
      await tester.tap(find.text('form ${AppRoutes.classForm}'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(const ListRequested()));
    });

    testWidgets('Add several hands over the Institution and the classes already added, and reads again once saved', (
      tester,
    ) async {
      final opened = await pumpWithForms(tester, const ListLoaded<SchoolClass>([class1, pucClass]), saved: true);
      await tester.tap(find.byKey(const Key('classes.addSeveral')));
      await tester.pumpAndSettle();
      final args = opened.single! as ClassBulkArgs;
      expect(args.institutionId, 'i1');
      expect(args.added, {'p1', 'p9'});
      await tester.tap(find.text('form ${AppRoutes.classBulk}'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const ListRequested())).called(1);
    });
  });

  group('the sections', () {
    testWidgets('the Sections button hands the class over, and reads the list again whatever happened there', (
      tester,
    ) async {
      final opened = await pumpWithForms(tester, const ListLoaded<SchoolClass>([class1, pucClass]), saved: false);
      await tester.tap(find.byKey(const ValueKey('class.sections.k9')));
      await tester.pumpAndSettle();
      expect((opened.single! as SectionsArgs).schoolClass, pucClass);
      verifyNever(() => bloc.add(const ListRequested()));
      await tester.tap(find.text('form ${AppRoutes.classSections}'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const ListRequested())).called(1);
    });

    testWidgets('while a deactivation is on its way, the Sections button waits too', (tester) async {
      await pump(tester, const ListLoaded<SchoolClass>([class1], busyId: 'k1'));
      final button = find.descendant(
        of: find.byKey(const ValueKey('class.sections.k1')),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
    });
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(
      tester,
      const ListLoaded<SchoolClass>([class1, pucClass]),
      textScale: 2,
      size: const Size(320, 1800),
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
