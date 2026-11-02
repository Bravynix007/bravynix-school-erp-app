import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/bloc/platform_due_bloc.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/view/platform_due_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/platform_dues.dart';
import '../../helpers/pump_app.dart';

class _MockDueBloc extends MockBloc<PlatformDueEvent, PlatformDueState> implements PlatformDueBloc;

void main() {
  late _MockDueBloc bloc;
  setUp(() => bloc = _MockDueBloc());

  DateTime clock() => DateTime.utc(2026, 11, 10, 6);

  Future<void> pump(WidgetTester tester, PlatformDueState state, {double textScale = 1}) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<PlatformDueBloc>.value(
        value: bloc,
        child: PlatformDueView(clock: clock),
      ),
      textScale: textScale,
      size: const Size(360, 1400),
    );
  }

  testWidgets('shows what the due is for and how the total was reached, with the note for the Owners', (tester) async {
    await pump(tester, PlatformDueLoaded(due()));
    expect(find.text('Sri Vidya High School'), findsOneWidget);
    expect(find.text('BNX/FY2026-27/0007'), findsOneWidget);
    expect(find.text('01-10-2026 to 31-12-2026'), findsOneWidget);
    expect(find.text('15-11-2026'), findsOneWidget);
    expect(find.text('1650 students × ₹50.00'), findsOneWidget);
    expect(find.text('₹82,500.00'), findsOneWidget);
    expect(find.text('Adjustment'), findsOneWidget);
    expect(find.text('-₹2,500.00'), findsOneWidget);
    expect(find.text('Festive discount'), findsOneWidget);
    expect(find.text('₹80,000.00'), findsOneWidget);
    expect(find.text('Payment'), findsNothing);
  });

  testWidgets('leaves the adjustment out when there is none, and says one student in the singular', (tester) async {
    await pump(tester, PlatformDueLoaded(due(adjustmentAmount: '0.00', adjustmentNote: null)));
    expect(find.text('Adjustment'), findsNothing);
  });

  testWidgets('shows how a paid due was paid', (tester) async {
    await pump(
      tester,
      PlatformDueLoaded(
        due(
          status: DueStatus.paid,
          paidDate: '2026-11-01',
          paymentMode: PaymentMode.bankTransfer,
          paymentReference: 'UTR 2291',
        ),
      ),
    );
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('01-11-2026'), findsOneWidget);
    expect(find.text('Bank transfer'), findsOneWidget);
    expect(find.text('UTR 2291'), findsOneWidget);
    expect(find.text('Pay by'), findsNothing);
  });

  testWidgets('says a cancelled due is not owed', (tester) async {
    await pump(tester, PlatformDueLoaded(due(status: DueStatus.cancelled)));
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Cancelled by BravyNix. You do not owe this.'), findsOneWidget);
  });

  testWidgets('marks an open due past its date as Overdue', (tester) async {
    await pump(tester, PlatformDueLoaded(due(dueDate: '2026-11-01')));
    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const PlatformDueLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and loads again on Try again', (tester) async {
    await pump(tester, const PlatformDueFailed(ApiFailure.network()));
    expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const PlatformDueRequested())).called(1);
  });

  testWidgets('says a due that is not this Society’s is not available, with nothing to retry', (tester) async {
    await pump(tester, const PlatformDueFailed(ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')));
    expect(find.text('This due is not available. It may have been removed.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('says a role that may not see dues has no access', (tester) async {
    await pump(tester, const PlatformDueFailed(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
    expect(find.text("You don't have access to this."), findsOneWidget);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(
      tester,
      PlatformDueLoaded(
        due(
          status: DueStatus.paid,
          paidDate: '2026-11-01',
          paymentMode: PaymentMode.bankTransfer,
          paymentReference: 'UTR 2291 0007 1234',
          adjustmentNote: 'A long note about the festive discount that BravyNix agreed with the Society Owners',
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester), isEmpty);
  });
}
