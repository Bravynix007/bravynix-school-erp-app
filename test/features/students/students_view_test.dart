import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_icon_button.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_filters_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/students_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_form_page.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/students_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/students.dart';

class _MockStudentsBloc extends MockBloc<PagedListEvent, PagedListState<StudentListEntry>> implements StudentsBloc;

class _MockFiltersBloc extends MockBloc<StudentFiltersEvent, StudentFiltersState> implements StudentFiltersBloc;

typedef _Loaded = PagedListLoaded<StudentListEntry>;

void main() {
  late _MockStudentsBloc bloc;
  late _MockFiltersBloc filters;
  setUpAll(() {
    registerFallbackValue(const PagedListRequested());
    registerFallbackValue(const StudentFiltersStarted());
  });
  setUp(() {
    bloc = _MockStudentsBloc();
    filters = _MockFiltersBloc();
    when(() => filters.state).thenReturn(const StudentFiltersReady(studentOptions));
  });

  Future<void> pump(
    WidgetTester tester,
    PagedListState<StudentListEntry> state, {
    double textScale = 1,
    Size size = const Size(400, 1200),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<StudentsBloc>.value(value: bloc),
            BlocProvider<StudentFiltersBloc>.value(value: filters),
          ],
          child: const StudentsView(),
        ),
      ),
      textScale: textScale,
      size: size,
    );
  }

  Finder button(String key) =>
      find.descendant(of: find.byKey(ValueKey(key)), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));

  testWidgets('lists each student with the class and section, roll number and Admission ID, and a Blocked badge', (
    tester,
  ) async {
    await pump(tester, const _Loaded([ashaEntry, balaEntry]));
    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('Class 1 · Section A · Roll 14 · ID A-2026-014'), findsOneWidget);
    expect(find.text('Bala'), findsOneWidget);
    expect(find.text('Roll 2'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
  });

  group('filters', () {
    testWidgets('are the year, the class and the section, none applied at first', (tester) async {
      await pump(tester, const _Loaded([ashaEntry]));
      expect(find.text('Year'), findsOneWidget);
      expect(find.text('Class'), findsOneWidget);
      expect(find.text('Section'), findsOneWidget);
      expect(find.text('Clear filters'), findsNothing);
    });

    testWidgets('show what is chosen, and Clear filters clears them', (tester) async {
      when(() => filters.state).thenReturn(
        const StudentFiltersReady(
          studentOptions,
          filter: StudentFilter(academicYearId: 'y1', classId: 'c1', sectionId: 'e2'),
        ),
      );
      await pump(tester, const _Loaded([ashaEntry]));
      expect(find.text('Year: 2026-2027'), findsOneWidget);
      expect(find.text('Class: Class 1'), findsOneWidget);
      expect(find.text('Section: Class 1 · Blue'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      verify(() => filters.add(const StudentFiltersCleared())).called(1);
    });

    testWidgets('open a sheet of choices, and send the one picked', (tester) async {
      await pump(tester, const _Loaded([ashaEntry]));
      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();
      expect(find.text('Any'), findsOneWidget);
      expect(find.text('2025-2026'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('studentFilter.option.y0')));
      await tester.pumpAndSettle();
      verify(() => filters.add(const StudentFiltersYearChosen('y0'))).called(1);
    });

    testWidgets('offer only the sections of the class chosen', (tester) async {
      when(() => filters.state).thenReturn(
        const StudentFiltersReady(studentOptions, filter: StudentFilter(classId: 'c2')),
      );
      await pump(tester, const _Loaded([ashaEntry]));
      await tester.tap(find.text('Section'));
      await tester.pumpAndSettle();
      expect(find.text('Class 2 · Section A'), findsOneWidget);
      expect(find.text('Class 1 · Blue'), findsNothing);
    });

    testWidgets('send null for Any', (tester) async {
      when(() => filters.state).thenReturn(
        const StudentFiltersReady(studentOptions, filter: StudentFilter(classId: 'c1')),
      );
      await pump(tester, const _Loaded([ashaEntry]));
      await tester.tap(find.text('Class: Class 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('studentFilter.any')));
      await tester.pumpAndSettle();
      verify(() => filters.add(const StudentFiltersClassChosen(null))).called(1);
    });

    testWidgets('send nothing when the sheet is dismissed', (tester) async {
      await pump(tester, const _Loaded([ashaEntry]));
      await tester.tap(find.text('Class'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      verifyNever(() => filters.add(any()));
    });

    testWidgets('wait while a deactivation goes', (tester) async {
      await pump(tester, const _Loaded([ashaEntry], busyId: 'p1'));
      await tester.tap(find.text('Year'));
      // The busy card spins, so the frames are pumped by hand.
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('studentFilter.any')), findsNothing);
    });

    testWidgets('are left out until the options are read', (tester) async {
      when(() => filters.state).thenReturn(const StudentFiltersLoading());
      await pump(tester, const _Loaded([ashaEntry]));
      expect(find.text('Year'), findsNothing);
    });

    testWidgets('pass the chosen filter on to the list', (tester) async {
      whenListen(
        filters,
        Stream.value(const StudentFiltersReady(studentOptions, filter: StudentFilter(classId: 'c1'))),
        initialState: const StudentFiltersReady(studentOptions),
      );
      await pump(tester, const _Loaded([ashaEntry]));
      await tester.pump();
      verify(() => bloc.add(const StudentsFiltered(StudentFilter(classId: 'c1')))).called(1);
    });
  });

  testWidgets('searches when the keyboard says search, and clears the search when the box is emptied', (tester) async {
    await pump(tester, const _Loaded([ashaEntry]));
    await tester.enterText(find.byKey(const Key('students.search')), 'ash');
    verifyNever(() => bloc.add(any(that: isA<PagedListSearched>())));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    verify(() => bloc.add(const PagedListSearched('ash'))).called(1);
    await tester.pump();
    await tester.tap(find.byType(AppIconButton));
    await tester.pump();
    verify(() => bloc.add(const PagedListSearched(''))).called(1);
  });

  testWidgets('locks the search box while a deactivation goes', (tester) async {
    await pump(tester, const _Loaded([ashaEntry], busyId: 'p1'));
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('never sends more than 100 letters, which is all STU-01 takes', (tester) async {
    await pump(tester, const _Loaded([ashaEntry]));
    await tester.enterText(find.byKey(const Key('students.search')), 'k' * 101);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    verify(() => bloc.add(PagedListSearched('k' * 100))).called(1);
  });

  group('Deactivate', () {
    testWidgets('asks why, offers the three reasons, and cannot go ahead without one', (tester) async {
      await pump(tester, const _Loaded([ashaEntry]));
      await tester.tap(find.byKey(const ValueKey('students.deactivate.p1')));
      await tester.pumpAndSettle();
      expect(find.text('Deactivate Asha Rao?'), findsOneWidget);
      expect(find.textContaining('Nothing is deleted.'), findsOneWidget);
      expect(find.text('Left the Institution'), findsOneWidget);
      expect(find.text('Added by mistake'), findsOneWidget);
      expect(find.text('Another reason'), findsOneWidget);
      expect(tester.widget<ButtonStyleButton>(button('studentLeaving.confirm')).onPressed, isNull);
    });

    testWidgets('does nothing when cancelled', (tester) async {
      await pump(tester, const _Loaded([ashaEntry]));
      await tester.tap(find.byKey(const ValueKey('students.deactivate.p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('studentLeaving.left')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('studentLeaving.cancel')));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any(that: isA<StudentDeactivated>())));
    });

    testWidgets('goes ahead with the reason chosen', (tester) async {
      await pump(tester, const _Loaded([ashaEntry]));
      await tester.tap(find.byKey(const ValueKey('students.deactivate.p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('studentLeaving.mistake')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('studentLeaving.confirm')));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StudentDeactivated(ashaEntry, LeavingReason.mistake))).called(1);
    });

    testWidgets('can change its mind about the reason before confirming', (tester) async {
      await pump(tester, const _Loaded([ashaEntry]));
      await tester.tap(find.byKey(const ValueKey('students.deactivate.p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('studentLeaving.mistake')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('studentLeaving.other')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('studentLeaving.confirm')));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StudentDeactivated(ashaEntry, LeavingReason.other))).called(1);
    });

    testWidgets('waits while a deactivation is on its way, on every card', (tester) async {
      await pump(tester, const _Loaded([ashaEntry, balaEntry], busyId: 'p1'));
      expect(tester.widget<ButtonStyleButton>(button('students.deactivate.p1')).onPressed, isNull);
      expect(tester.widget<ButtonStyleButton>(button('students.deactivate.p2')).onPressed, isNull);
    });

    testWidgets('says why it was refused, above the list', (tester) async {
      await pump(
        tester,
        const _Loaded(
          [ashaEntry],
          actionFailure: ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x'),
        ),
      );
      expect(find.byKey(const Key('students.actionFailed')), findsOneWidget);
      expect(find.text('This student could not be found. They may have been deactivated.'), findsOneWidget);
    });

    testWidgets('says which student was deactivated', (tester) async {
      whenListen(
        bloc,
        Stream.value(const _Loaded([balaEntry], changed: ashaEntry)),
        initialState: const _Loaded([ashaEntry, balaEntry]),
      );
      await tester.pumpAppScaled(
        Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<StudentsBloc>.value(value: bloc),
              BlocProvider<StudentFiltersBloc>.value(value: filters),
            ],
            child: const StudentsView(),
          ),
        ),
        size: const Size(400, 1200),
      );
      await tester.pump();
      expect(find.text('Asha Rao deactivated'), findsOneWidget);
    });
  });

  group('Load more', () {
    testWidgets('is offered while there is another page, and asks for it', (tester) async {
      await pump(tester, const _Loaded([ashaEntry], hasMore: true));
      await tester.tap(find.byKey(const Key('students.more')));
      verify(() => bloc.add(const PagedListMoreRequested())).called(1);
    });

    testWidgets('is not offered on the last page', (tester) async {
      await pump(tester, const _Loaded([ashaEntry]));
      expect(find.byKey(const Key('students.more')), findsNothing);
    });

    testWidgets('says why it failed, and offers Try again', (tester) async {
      await pump(tester, const _Loaded([ashaEntry], hasMore: true, moreFailure: ApiFailure.network()));
      expect(find.byKey(const Key('students.moreFailed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const PagedListMoreRequested())).called(1);
    });
  });

  group('Add student', () {
    /// The list on a router that has the form's location, which closes with [result] (null: backed out).
    Future<List<StudentFormArgs>> pumpWithForm(
      WidgetTester tester,
      PagedListState<StudentListEntry> state, {
      required bool? result,
    }) async {
      when(() => bloc.state).thenReturn(state);
      when(() => bloc.institutionId).thenReturn('i1');
      final opened = <StudentFormArgs>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: MultiBlocProvider(
                providers: [
                  BlocProvider<StudentsBloc>.value(value: bloc),
                  BlocProvider<StudentFiltersBloc>.value(value: filters),
                ],
                child: const StudentsView(),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.studentForm,
            builder: (context, routeState) {
              opened.add(routeState.extra! as StudentFormArgs);
              return Scaffold(
                body: TextButton(onPressed: () => context.pop(result), child: const Text('close form')),
              );
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

    testWidgets('opens the form for this Institution, and reads the list again once a student was saved', (
      tester,
    ) async {
      final opened = await pumpWithForm(tester, const _Loaded([ashaEntry]), result: true);
      await tester.tap(find.byKey(const Key('students.add')));
      await tester.pumpAndSettle();
      expect(opened.single.institutionId, 'i1');
      await tester.tap(find.text('close form'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const PagedListRequested())).called(1);
    });

    testWidgets('leaves the list alone when the form closed without saving', (tester) async {
      await pumpWithForm(tester, const _Loaded([ashaEntry]), result: null);
      await tester.tap(find.byKey(const Key('students.add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('close form'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(const PagedListRequested()));
    });

    testWidgets('is offered on an empty list as well', (tester) async {
      final opened = await pumpWithForm(tester, const _Loaded([]), result: true);
      await tester.tap(find.text('Add student'));
      await tester.pumpAndSettle();
      expect(opened.single.institutionId, 'i1');
    });

    testWidgets('waits while a deactivation goes', (tester) async {
      await pump(tester, const _Loaded([ashaEntry], busyId: 'p1'));
      expect(tester.widget<ButtonStyleButton>(button('students.add')).onPressed, isNull);
    });
  });

  group('an empty list', () {
    testWidgets('says there are no students yet when nothing is searched or filtered', (tester) async {
      await pump(tester, const _Loaded([]));
      expect(find.text('No students yet'), findsOneWidget);
    });

    testWidgets('says nothing matches a search that found no one', (tester) async {
      await pump(tester, const _Loaded([], query: 'zzz'));
      expect(find.byKey(const Key('students.noMatch')), findsOneWidget);
      expect(find.text('No students match "zzz"'), findsOneWidget);
    });

    testWidgets('says nothing is in the selection when filters are applied', (tester) async {
      when(() => filters.state).thenReturn(
        const StudentFiltersReady(studentOptions, filter: StudentFilter(classId: 'c2')),
      );
      await pump(tester, const _Loaded([]));
      expect(find.byKey(const Key('students.noFilterMatch')), findsOneWidget);
      expect(find.text('No students yet'), findsNothing);
    });
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const PagedListLoading<StudentListEntry>());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  group('Try again', () {
    testWidgets('says why it failed, and loads the list again, leaving the filters that are chosen as they are', (
      tester,
    ) async {
      when(() => filters.state).thenReturn(
        const StudentFiltersReady(studentOptions, filter: StudentFilter(classId: 'c2')),
      );
      await pump(tester, const PagedListFailed<StudentListEntry>(ApiFailure.network()));
      expect(find.byKey(const Key('students.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const PagedListRequested())).called(1);
      verifyNever(() => filters.add(any()));
    });

    testWidgets('also reads the filters again when they failed', (tester) async {
      when(() => filters.state).thenReturn(const StudentFiltersFailed(ApiFailure.network()));
      await pump(tester, const PagedListFailed<StudentListEntry>(ApiFailure.network()));
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const PagedListRequested())).called(1);
      verify(() => filters.add(const StudentFiltersStarted())).called(1);
    });
  });

  testWidgets('says a role that may not see students has no access', (tester) async {
    await pump(
      tester,
      const PagedListFailed<StudentListEntry>(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')),
    );
    expect(find.byKey(const Key('students.forbidden')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, const _Loaded([ashaEntry, balaEntry], hasMore: true), textScale: 2, size: const Size(320, 2400));
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });

  testWidgets('the sheet of reasons reads whole at a large text scale', (tester) async {
    await pump(tester, const _Loaded([ashaEntry]), textScale: 2, size: const Size(320, 1200));
    await tester.tap(find.byKey(const ValueKey('students.deactivate.p1')));
    await tester.pumpAndSettle();
    expect(find.text('Left the Institution'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
