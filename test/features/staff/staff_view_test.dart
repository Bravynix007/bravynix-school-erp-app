import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_icon_button.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/staff.dart';

class _MockStaffBloc extends MockBloc<PagedListEvent, PagedListState<StaffListEntry>> implements StaffBloc;

typedef _Loaded = PagedListLoaded<StaffListEntry>;

void main() {
  late _MockStaffBloc bloc;
  setUpAll(() {
    registerFallbackValue(const PagedListRequested());
    registerFallbackValue(const StaffDeactivated(kavyaEntry));
  });
  setUp(() => bloc = _MockStaffBloc());

  Future<void> pump(
    WidgetTester tester,
    PagedListState<StaffListEntry> state, {
    double textScale = 1,
    Size size = const Size(400, 1200),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      Scaffold(
        body: BlocProvider<StaffBloc>.value(value: bloc, child: const StaffView()),
      ),
      textScale: textScale,
      size: size,
    );
  }

  Finder button(String key) =>
      find.descendant(of: find.byKey(ValueKey(key)), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));

  testWidgets('lists each staff member with the Employee ID, designation and category, and a Blocked badge', (
    tester,
  ) async {
    await pump(tester, const _Loaded([kavyaEntry, raviEntry]));
    expect(find.text('Kavya Nair'), findsOneWidget);
    expect(find.text('T-014 · Mathematics Teacher · Lower Primary'), findsOneWidget);
    expect(find.text('Ravi'), findsOneWidget);
    expect(find.text('Lower Primary'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
  });

  testWidgets('opens the profile of the one tapped', (tester) async {
    when(() => bloc.state).thenReturn(const _Loaded([kavyaEntry, raviEntry]));
    final opened = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: BlocProvider<StaffBloc>.value(value: bloc, child: const StaffView()),
          ),
        ),
        GoRoute(
          path: AppRoutes.staffMemberPattern,
          builder: (_, state) {
            opened.add(state.pathParameters['id']!);
            return const Text('profile');
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
    await tester.tap(find.text('Ravi'));
    await tester.pumpAndSettle();
    expect(opened, ['f2']);
  });

  testWidgets('searches when the keyboard says search, and clears the search when the box is emptied', (tester) async {
    await pump(tester, const _Loaded([kavyaEntry]));
    await tester.enterText(find.byKey(const Key('staff.search')), 'kav');
    verifyNever(() => bloc.add(any(that: isA<PagedListSearched>())));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    verify(() => bloc.add(const PagedListSearched('kav'))).called(1);
    await tester.pump();
    await tester.tap(find.byType(AppIconButton));
    await tester.pump();
    verify(() => bloc.add(const PagedListSearched(''))).called(1);
  });

  testWidgets('Deactivate asks first, and does nothing when cancelled', (tester) async {
    await pump(tester, const _Loaded([kavyaEntry]));
    await tester.tap(find.byKey(const ValueKey('staff.deactivate.f1')));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate Kavya Nair?'), findsOneWidget);
    expect(find.textContaining('Nothing is deleted.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any(that: isA<StaffDeactivated>())));
  });

  testWidgets('Deactivate goes ahead once confirmed', (tester) async {
    await pump(tester, const _Loaded([kavyaEntry]));
    await tester.tap(find.byKey(const ValueKey('staff.deactivate.f1')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Deactivate')));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const StaffDeactivated(kavyaEntry))).called(1);
  });

  testWidgets('while a deactivation is on its way, no card starts another change or opens a profile', (tester) async {
    await pump(tester, const _Loaded([kavyaEntry, raviEntry], busyId: 'f1'));
    expect(tester.widget<ButtonStyleButton>(button('staff.deactivate.f1')).onPressed, isNull);
    expect(tester.widget<ButtonStyleButton>(button('staff.deactivate.f2')).onPressed, isNull);
  });

  testWidgets('says why a deactivation was refused, above the list', (tester) async {
    await pump(
      tester,
      const _Loaded(
        [kavyaEntry],
        actionFailure: ApiFailure(statusCode: 409, code: 'CANNOT_ACT_ON_SELF', message: 'x'),
      ),
    );
    expect(find.byKey(const Key('staff.actionFailed')), findsOneWidget);
    expect(find.text("You can't do this to your own record."), findsOneWidget);
  });

  testWidgets('says which staff member was deactivated', (tester) async {
    whenListen(
      bloc,
      Stream.value(const _Loaded([raviEntry], changed: kavyaEntry)),
      initialState: const _Loaded([kavyaEntry, raviEntry]),
    );
    await tester.pumpAppScaled(
      Scaffold(
        body: BlocProvider<StaffBloc>.value(value: bloc, child: const StaffView()),
      ),
      size: const Size(400, 1200),
    );
    await tester.pump();
    expect(find.text('Kavya Nair deactivated'), findsOneWidget);
  });

  group('Load more', () {
    testWidgets('is offered while there is another page, and asks for it', (tester) async {
      await pump(tester, const _Loaded([kavyaEntry], hasMore: true));
      await tester.tap(find.byKey(const Key('staff.more')));
      verify(() => bloc.add(const PagedListMoreRequested())).called(1);
    });

    testWidgets('is not offered on the last page', (tester) async {
      await pump(tester, const _Loaded([kavyaEntry]));
      expect(find.byKey(const Key('staff.more')), findsNothing);
    });

    testWidgets('waits while a change is on its way', (tester) async {
      await pump(tester, const _Loaded([kavyaEntry], hasMore: true, busyId: 'f1'));
      expect(tester.widget<ButtonStyleButton>(button('staff.more')).onPressed, isNull);
    });

    testWidgets('says why it failed, and offers Try again', (tester) async {
      await pump(
        tester,
        const _Loaded([kavyaEntry], hasMore: true, moreFailure: ApiFailure.network()),
      );
      expect(find.byKey(const Key('staff.moreFailed')), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const PagedListMoreRequested())).called(1);
    });
  });

  testWidgets('says there is no staff yet when the list is empty with no search', (tester) async {
    await pump(tester, const _Loaded([]));
    expect(find.text('No staff yet'), findsOneWidget);
  });

  testWidgets('says nothing matches a search that found no one', (tester) async {
    await pump(tester, const _Loaded([], query: 'zzz'));
    expect(find.byKey(const Key('staff.noMatch')), findsOneWidget);
    expect(find.text('No staff match "zzz"'), findsOneWidget);
    expect(find.text('No staff yet'), findsNothing);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const PagedListLoading<StaffListEntry>());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and loads again on Try again', (tester) async {
    await pump(tester, const PagedListFailed<StaffListEntry>(ApiFailure.network()));
    expect(find.byKey(const Key('staff.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const PagedListRequested())).called(1);
  });

  testWidgets('says a role that may not see staff has no access', (tester) async {
    await pump(
      tester,
      const PagedListFailed<StaffListEntry>(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')),
    );
    expect(find.byKey(const Key('staff.forbidden')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(
      tester,
      const _Loaded([kavyaEntry, raviEntry], hasMore: true),
      textScale: 2,
      size: const Size(320, 2400),
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
