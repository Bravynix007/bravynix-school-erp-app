import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slot.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/bloc/time_slots_bloc.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/view/time_slot_form_page.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/view/time_slots_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/time_slots.dart';

class _MockSlotsBloc extends MockBloc<ListEvent, ListState<TimeSlot>> implements TimeSlotsBloc;

void main() {
  late _MockSlotsBloc bloc;
  setUpAll(() {
    registerFallbackValue(const ListRequested());
    registerFallbackValue(const TimeSlotDeactivated(firstPeriod));
  });
  setUp(() {
    bloc = _MockSlotsBloc();
    when(() => bloc.institutionId).thenReturn('i1');
  });

  Widget view() => Scaffold(
    body: BlocProvider<TimeSlotsBloc>.value(value: bloc, child: const TimeSlotsView()),
  );

  Future<void> pump(WidgetTester tester, ListState<TimeSlot> state, {double textScale = 1}) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(view(), textScale: textScale, size: const Size(400, 1200));
  }

  /// The list on a router, with the form route answering [saved] when it closes, and recording what it was given.
  Future<List<Object?>> pumpWithForm(WidgetTester tester, ListState<TimeSlot> state, {required bool saved}) async {
    when(() => bloc.state).thenReturn(state);
    final opened = <Object?>[];
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => view()),
        GoRoute(
          path: AppRoutes.timeSlotForm,
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

  testWidgets('lists each period with its times, naming one by its number unless the school named it', (tester) async {
    await pump(tester, const ListLoaded<TimeSlot>([firstPeriod, lunch]));
    expect(find.text('Period 1'), findsOneWidget);
    expect(find.text('09:00 to 09:45'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('12:00 to 12:30'), findsOneWidget);
    expect(find.text('Break'), findsOneWidget);
  });

  testWidgets('Deactivate asks first, and does nothing when cancelled', (tester) async {
    await pump(tester, const ListLoaded<TimeSlot>([firstPeriod, lunch]));
    await tester.tap(find.byKey(const ValueKey('timeSlot.deactivate.t2')));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate Lunch?'), findsOneWidget);
    expect(
      find.text('It leaves the list and its number and times are free again. Nothing is deleted.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any(that: isA<TimeSlotDeactivated>())));
  });

  testWidgets('Deactivate goes ahead once confirmed', (tester) async {
    await pump(tester, const ListLoaded<TimeSlot>([firstPeriod, lunch]));
    await tester.tap(find.byKey(const ValueKey('timeSlot.deactivate.t1')));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate Period 1?'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Deactivate')));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const TimeSlotDeactivated(firstPeriod))).called(1);
  });

  testWidgets('while a change is on its way, no period can be changed again', (tester) async {
    await pump(tester, const ListLoaded<TimeSlot>([firstPeriod, lunch], busyId: 't2'));
    OutlinedButton buttonOf(String key) => tester.widget<OutlinedButton>(
      find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(OutlinedButton)),
    );
    expect(buttonOf('timeSlot.edit.t2').onPressed, isNull);
    expect(buttonOf('timeSlot.edit.t1').onPressed, isNull);
  });

  testWidgets('says why a change was refused, above the list', (tester) async {
    await pump(
      tester,
      const ListLoaded<TimeSlot>(
        [firstPeriod, lunch],
        actionFailure: ApiFailure(statusCode: 409, code: 'TIME_SLOT_IN_USE', message: 'x'),
      ),
    );
    expect(find.byKey(const Key('timeSlots.actionFailed')), findsOneWidget);
    expect(find.text('A timetable entry sits in this period. Remove it from the timetable first.'), findsOneWidget);
  });

  testWidgets('says a period was deactivated', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([
        const ListLoaded<TimeSlot>([firstPeriod], changed: lunch),
      ]),
      initialState: const ListLoaded<TimeSlot>([firstPeriod, lunch]),
    );
    await tester.pumpAppScaled(view(), size: const Size(400, 1200));
    await tester.pump();
    expect(find.text('Period deactivated'), findsOneWidget);
  });

  testWidgets('invites the first period when there is none', (tester) async {
    await pump(tester, const ListLoaded<TimeSlot>([]));
    expect(find.text('No periods yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add period'), findsOneWidget);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const ListLoading<TimeSlot>());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and loads again on Try again', (tester) async {
    await pump(tester, const ListFailed<TimeSlot>(ApiFailure.network()));
    expect(find.byKey(const Key('timeSlots.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const ListRequested())).called(1);
  });

  testWidgets('says an Institution with no current year needs one', (tester) async {
    await pump(
      tester,
      const ListFailed<TimeSlot>(ApiFailure(statusCode: 422, code: 'CURRENT_YEAR_REQUIRED', message: 'x')),
    );
    expect(find.textContaining('has no current academic year'), findsOneWidget);
  });

  testWidgets('says a role that may not see period timings has no access', (tester) async {
    await pump(tester, const ListFailed<TimeSlot>(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
    expect(find.byKey(const Key('timeSlots.forbidden')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  group('the form', () {
    testWidgets('Add opens it for this Institution with no period, and reads the list again once saved', (
      tester,
    ) async {
      final opened = await pumpWithForm(tester, const ListLoaded<TimeSlot>([firstPeriod]), saved: true);
      await tester.tap(find.byKey(const Key('timeSlots.add')));
      await tester.pumpAndSettle();
      final args = opened.single! as TimeSlotFormArgs;
      expect(args.institutionId, 'i1');
      expect(args.slot, isNull);
      verifyNever(() => bloc.add(const ListRequested()));
      await tester.tap(find.text('form'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const ListRequested())).called(1);
    });

    testWidgets('the empty list opens it too', (tester) async {
      final opened = await pumpWithForm(tester, const ListLoaded<TimeSlot>([]), saved: false);
      await tester.tap(find.widgetWithText(FilledButton, 'Add period'));
      await tester.pumpAndSettle();
      expect((opened.single! as TimeSlotFormArgs).slot, isNull);
    });

    testWidgets('Edit hands the period over, and leaves the list alone when the form was cancelled', (tester) async {
      final opened = await pumpWithForm(tester, const ListLoaded<TimeSlot>([firstPeriod, lunch]), saved: false);
      await tester.tap(find.byKey(const ValueKey('timeSlot.edit.t2')));
      await tester.pumpAndSettle();
      expect((opened.single! as TimeSlotFormArgs).slot, lunch);
      await tester.tap(find.text('form'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(const ListRequested()));
    });
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, const ListLoaded<TimeSlot>([firstPeriod, lunch]), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 400 - 4 * 16), isEmpty);
  });
}
