import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/classroom/domain/classroom.dart';
import 'package:bravynix_school_erp/features/classroom/presentation/bloc/classroom_bloc.dart';
import 'package:bravynix_school_erp/features/classroom/presentation/view/classroom_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/classroom.dart';
import '../../helpers/clipped_text.dart';

class _MockClassroomBloc extends MockBloc<PagedListEvent, PagedListState<ClassroomEntry>> implements ClassroomBloc;

ApiFailure _failure(int status, String code) => ApiFailure(statusCode: status, code: code, message: 'x');

void main() {
  late _MockClassroomBloc bloc;

  setUpAll(() => registerFallbackValue(const PagedListRequested()));
  setUp(() => bloc = _MockClassroomBloc());

  Future<void> pump(WidgetTester tester, PagedListState<ClassroomEntry> state, {double textScale = 1}) {
    when(() => bloc.state).thenReturn(state);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: BlocProvider<ClassroomBloc>.value(value: bloc, child: const ClassroomView()),
          ),
        ),
        GoRoute(
          path: AppRoutes.classroomStudentPattern,
          builder: (_, state) => Text('student ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    tester.view
      ..physicalSize = const Size(320, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    );
  }

  testWidgets('shows each student with their section and roll number, and nothing to change', (tester) async {
    await pump(tester, const PagedListLoaded<ClassroomEntry>([ashaEntry, balaEntry]));
    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('Class 1 · Section A · Roll 14'), findsOneWidget);
    expect(find.text('Bala'), findsOneWidget);
    expect(find.text('Roll 3'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('opens the student of the card tapped', (tester) async {
    await pump(tester, const PagedListLoaded<ClassroomEntry>([ashaEntry]));
    await tester.tap(find.text('Asha Rao'));
    await tester.pumpAndSettle();
    expect(find.text('student p1'), findsOneWidget);
  });

  testWidgets('says no student is in the sections yet', (tester) async {
    await pump(tester, const PagedListLoaded<ClassroomEntry>([]));
    expect(find.text('No students in your sections yet'), findsOneWidget);
  });

  testWidgets('says no student matches the search, and offers the roll number', (tester) async {
    await pump(tester, const PagedListLoaded<ClassroomEntry>([], query: 'zz'));
    expect(find.byKey(const Key('classroom.noMatch')), findsOneWidget);
    expect(find.text('Check the spelling, or search by roll number.'), findsOneWidget);
  });

  testWidgets('says why the list could not be read, and reads again on Try again', (tester) async {
    await pump(tester, PagedListFailed<ClassroomEntry>(_failure(503, 'UNAVAILABLE')));
    expect(find.byKey(const Key('classroom.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const PagedListRequested())).called(1);
  });

  testWidgets('says there is no access', (tester) async {
    await pump(tester, PagedListFailed<ClassroomEntry>(_failure(403, 'FORBIDDEN')));
    expect(find.byType(StatePanel), findsOneWidget);
    expect(find.byKey(const Key('classroom.forbidden')), findsOneWidget);
  });

  testWidgets('fits a narrow phone at a large text size', (tester) async {
    await pump(tester, const PagedListLoaded<ClassroomEntry>([ashaEntry, balaEntry]), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 196), isEmpty);
  });
}
