import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/bloc/platform_dues_bloc.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/view/platform_dues_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/platform_dues.dart';
import '../../helpers/pump_app.dart';

class _MockDuesBloc extends MockBloc<PlatformDuesEvent, PlatformDuesState> implements PlatformDuesBloc;

void main() {
  late _MockDuesBloc bloc;
  setUp(() => bloc = _MockDuesBloc());

  // 20-11-2026: five days after the first due's date.
  DateTime clock() => DateTime.utc(2026, 11, 20, 6);

  Future<void> pump(WidgetTester tester, PlatformDuesState state, {double textScale = 1}) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<PlatformDuesBloc>.value(
        value: bloc,
        child: PlatformDuesView(clock: clock),
      ),
      textScale: textScale,
    );
  }

  PlatformDuesLoaded loaded(List<PlatformDueLine> dues, {String total = '80000.00', bool open = true}) =>
      PlatformDuesLoaded(PlatformDues(totalDueAmount: total, hasOpenDues: open, dues: dues));

  testWidgets('says "You are due" with the amount, and lists each due with its status', (tester) async {
    await pump(
      tester,
      loaded([
        dueLine(),
        dueLine(
          id: 'd2',
          invoiceNo: 'BNX/FY2026-27/0006',
          totalAmount: '1000.00',
          status: DueStatus.paid,
          paidDate: '2026-11-01',
          paymentMode: PaymentMode.upi,
        ),
        dueLine(id: 'd3', invoiceNo: 'BNX/FY2026-27/0005', status: DueStatus.cancelled),
      ]),
    );
    expect(find.text('You are due ₹80,000.00'), findsOneWidget);
    expect(find.text('All dues are paid'), findsNothing);
    expect(find.text('BNX/FY2026-27/0007'), findsOneWidget);
    expect(find.text('Sri Vidya High School'), findsNWidgets(3));
    expect(find.text('01-10-2026 to 31-12-2026'), findsNWidgets(3));
    expect(find.text('Pay by 15-11-2026'), findsOneWidget);
    expect(find.text('Paid on 01-11-2026'), findsOneWidget);
    expect(find.text('Due'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('marks a due that is past its date as Overdue, in words and not only in colour', (tester) async {
    await pump(tester, loaded([dueLine(), dueLine(id: 'd2', invoiceNo: 'BNX/FY2026-27/0006', dueDate: '2026-12-01')]));
    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('says "All dues are paid" when nothing is owed, though dues are listed', (tester) async {
    await pump(
      tester,
      loaded(
        [dueLine(status: DueStatus.paid, paidDate: '2026-11-01')],
        total: '0.00',
        open: false,
      ),
    );
    expect(find.text('All dues are paid'), findsOneWidget);
    expect(find.text('Nothing is waiting for payment.'), findsOneWidget);
    expect(find.textContaining('You are due'), findsNothing);
  });

  testWidgets('says there is nothing yet when BravyNix has charged nothing', (tester) async {
    await pump(tester, loaded([], total: '0.00', open: false));
    expect(find.text('No dues yet'), findsOneWidget);
    expect(find.byKey(const Key('platformDues.banner')), findsNothing);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const PlatformDuesLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and loads again on Try again', (tester) async {
    await pump(tester, const PlatformDuesFailed(ApiFailure.network()));
    expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const PlatformDuesRequested())).called(1);
  });

  testWidgets('says a role that may not see dues has no access', (tester) async {
    await pump(tester, const PlatformDuesFailed(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
    expect(find.text("You don't have access to this."), findsOneWidget);
  });

  testWidgets('opens a due from its card', (tester) async {
    when(() => bloc.state).thenReturn(loaded([dueLine()]));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => BlocProvider<PlatformDuesBloc>.value(
            value: bloc,
            child: PlatformDuesView(clock: clock),
          ),
        ),
        GoRoute(path: AppRoutes.platformDuePattern, builder: (_, state) => Text('due ${state.pathParameters['id']}')),
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
    await tester.tap(find.byKey(const ValueKey('due.d1')));
    await tester.pumpAndSettle();
    expect(find.text('due d1'), findsOneWidget);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(
      tester,
      loaded([
        dueLine(totalAmount: '12345678.90', institutionName: 'Sri Vidya Educational Society Senior Secondary School'),
        dueLine(id: 'd2', status: DueStatus.paid, paidDate: '2026-11-01'),
      ], total: '12345678.90'),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
