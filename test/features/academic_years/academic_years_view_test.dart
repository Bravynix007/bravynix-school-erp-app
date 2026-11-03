import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/bloc/academic_years_bloc.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/view/academic_year_form_page.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/view/academic_years_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';

class _MockYearsBloc extends MockBloc<AcademicYearsEvent, AcademicYearsState> implements AcademicYearsBloc;

void main() {
  late _MockYearsBloc bloc;
  setUpAll(() {
    registerFallbackValue(const AcademicYearsRequested());
    registerFallbackValue(const AcademicYearDeactivated(currentYear));
  });
  setUp(() {
    bloc = _MockYearsBloc();
    when(() => bloc.institutionId).thenReturn('i1');
  });

  Future<void> pump(WidgetTester tester, AcademicYearsState state, {double textScale = 1}) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      Scaffold(
        body: BlocProvider<AcademicYearsBloc>.value(value: bloc, child: const AcademicYearsView()),
      ),
      textScale: textScale,
      size: const Size(400, 1200),
    );
  }

  /// The list on a router, with the form route answering [saved] when it closes, and recording what it was given.
  Future<List<Object?>> pumpWithForm(WidgetTester tester, AcademicYearsState state, {required bool saved}) async {
    when(() => bloc.state).thenReturn(state);
    final opened = <Object?>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: BlocProvider<AcademicYearsBloc>.value(value: bloc, child: const AcademicYearsView()),
          ),
        ),
        GoRoute(
          path: AppRoutes.academicYearForm,
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

  testWidgets('lists each year with its dates, and marks the current one', (tester) async {
    await pump(tester, const AcademicYearsLoaded([currentYear, earlierYear]));
    expect(find.text('2026-2027'), findsOneWidget);
    expect(find.text('01-06-2026 to 31-03-2027'), findsOneWidget);
    expect(find.text('2025-2026'), findsOneWidget);
    expect(find.text('01-06-2025 to 31-03-2026'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
  });

  testWidgets('the current year can be edited but not made current again or deactivated', (tester) async {
    await pump(tester, const AcademicYearsLoaded([currentYear, earlierYear]));
    expect(find.byKey(const ValueKey('academicYear.edit.y1')), findsOneWidget);
    expect(find.byKey(const ValueKey('academicYear.makeCurrent.y1')), findsNothing);
    expect(find.byKey(const ValueKey('academicYear.deactivate.y1')), findsNothing);
    expect(find.byKey(const ValueKey('academicYear.makeCurrent.y0')), findsOneWidget);
    expect(find.byKey(const ValueKey('academicYear.deactivate.y0')), findsOneWidget);
  });

  testWidgets('Make current asks for it without a confirmation', (tester) async {
    await pump(tester, const AcademicYearsLoaded([currentYear, earlierYear]));
    await tester.tap(find.byKey(const ValueKey('academicYear.makeCurrent.y0')));
    verify(() => bloc.add(const AcademicYearMadeCurrent(earlierYear))).called(1);
  });

  testWidgets('Deactivate asks first, and does nothing when cancelled', (tester) async {
    await pump(tester, const AcademicYearsLoaded([currentYear, earlierYear]));
    await tester.tap(find.byKey(const ValueKey('academicYear.deactivate.y0')));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate 2025-2026?'), findsOneWidget);
    expect(find.text('It leaves the list and its dates are free again. Nothing is deleted.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any(that: isA<AcademicYearDeactivated>())));
  });

  testWidgets('Deactivate goes ahead once confirmed', (tester) async {
    await pump(tester, const AcademicYearsLoaded([currentYear, earlierYear]));
    await tester.tap(find.byKey(const ValueKey('academicYear.deactivate.y0')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Deactivate')));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const AcademicYearDeactivated(earlierYear))).called(1);
  });

  testWidgets('while a change is on its way, that year cannot be changed again', (tester) async {
    await pump(tester, const AcademicYearsLoaded([currentYear, earlierYear], busyId: 'y0'));
    OutlinedButton buttonOf(String key) => tester.widget<OutlinedButton>(
      find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(OutlinedButton)),
    );
    expect(buttonOf('academicYear.makeCurrent.y0').onPressed, isNull);
    expect(buttonOf('academicYear.edit.y0').onPressed, isNull);
    expect(buttonOf('academicYear.edit.y1').onPressed, isNotNull);
  });

  testWidgets('says why a change was refused, above the list', (tester) async {
    await pump(
      tester,
      const AcademicYearsLoaded([
        currentYear,
        earlierYear,
      ], actionFailure: ApiFailure(statusCode: 409, code: 'CURRENT_YEAR_LOCKED', message: 'x')),
    );
    expect(find.byKey(const Key('academicYears.actionFailed')), findsOneWidget);
    expect(find.text("The current year can't be deactivated. Make another year current first."), findsOneWidget);
  });

  testWidgets('says that a year was made current', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([
        const AcademicYearsLoaded(
          [earlierYearMadeCurrent, currentYearDemoted],
          notice: AcademicYearsNotice.madeCurrent,
          noticeYear: earlierYear,
        ),
      ]),
      initialState: const AcademicYearsLoaded([currentYear, earlierYear]),
    );
    await tester.pumpAppScaled(
      Scaffold(
        body: BlocProvider<AcademicYearsBloc>.value(value: bloc, child: const AcademicYearsView()),
      ),
      size: const Size(400, 1200),
    );
    await tester.pump();
    expect(find.text('2025-2026 is now the current year'), findsOneWidget);
  });

  testWidgets('says a year was deactivated', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([
        const AcademicYearsLoaded([currentYear], notice: AcademicYearsNotice.deactivated, noticeYear: earlierYear),
      ]),
      initialState: const AcademicYearsLoaded([currentYear, earlierYear]),
    );
    await tester.pumpAppScaled(
      Scaffold(
        body: BlocProvider<AcademicYearsBloc>.value(value: bloc, child: const AcademicYearsView()),
      ),
      size: const Size(400, 1200),
    );
    await tester.pump();
    expect(find.text('Academic year deactivated'), findsOneWidget);
  });

  testWidgets('invites the first year when there is none', (tester) async {
    await pump(tester, const AcademicYearsLoaded([]));
    expect(find.text('No academic years yet'), findsOneWidget);
    expect(find.text('Add the first year. It becomes the current year.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add academic year'), findsOneWidget);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const AcademicYearsLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and loads again on Try again', (tester) async {
    await pump(tester, const AcademicYearsFailed(ApiFailure.network()));
    expect(find.byKey(const Key('academicYears.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const AcademicYearsRequested())).called(1);
  });

  testWidgets('says a role that may not see academic years has no access', (tester) async {
    await pump(tester, const AcademicYearsFailed(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
    expect(find.byKey(const Key('academicYears.forbidden')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  group('the form', () {
    testWidgets('Add opens it for this Institution with no year, and reads the list again once saved', (tester) async {
      final opened = await pumpWithForm(tester, const AcademicYearsLoaded([currentYear]), saved: true);
      await tester.tap(find.byKey(const Key('academicYears.add')));
      await tester.pumpAndSettle();
      final args = opened.single! as AcademicYearFormArgs;
      expect(args.institutionId, 'i1');
      expect(args.year, isNull);
      verifyNever(() => bloc.add(const AcademicYearsRequested()));
      await tester.tap(find.text('form'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const AcademicYearsRequested())).called(1);
    });

    testWidgets('the empty list opens it too', (tester) async {
      final opened = await pumpWithForm(tester, const AcademicYearsLoaded([]), saved: false);
      await tester.tap(find.widgetWithText(FilledButton, 'Add academic year'));
      await tester.pumpAndSettle();
      expect((opened.single! as AcademicYearFormArgs).year, isNull);
    });

    testWidgets('Edit hands the year over, and leaves the list alone when the form was cancelled', (tester) async {
      final opened = await pumpWithForm(tester, const AcademicYearsLoaded([currentYear, earlierYear]), saved: false);
      await tester.tap(find.byKey(const ValueKey('academicYear.edit.y0')));
      await tester.pumpAndSettle();
      expect((opened.single! as AcademicYearFormArgs).year, earlierYear);
      await tester.tap(find.text('form'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(const AcademicYearsRequested()));
    });
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, const AcademicYearsLoaded([currentYear, earlierYear]), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 400 - 4 * 16), isEmpty);
  });
}
