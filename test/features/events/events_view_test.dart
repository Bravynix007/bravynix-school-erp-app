import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/event_bloc.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/events_bloc.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_page.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/events_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/events.dart';
import '../../helpers/pump_app.dart';

class _MockEventsBloc extends MockBloc<EventsEvent, EventsState> implements EventsBloc;

class _MockEventBloc extends MockBloc<EventEvent, EventState> implements EventBloc;

void main() {
  final november = DateTime(2026, 11);
  final annual = schoolEvent();
  final diwali = schoolEvent(
    id: 'e2',
    title: 'Diwali break',
    isHoliday: true,
    venue: null,
    holidayType: HolidayType.vacation,
    forStudents: true,
    forStaff: true,
    classIds: ['c1', 'c2'],
    endDate: DateTime(2026, 11, 22),
  );

  group('events list', () {
    late _MockEventsBloc bloc;
    setUpAll(() {
      registerFallbackValue(const EventsRequested());
    });
    setUp(() => bloc = _MockEventsBloc());

    Future<void> pump(WidgetTester tester, EventsState state, {double textScale = 1}) {
      when(() => bloc.state).thenReturn(state);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: BlocProvider<EventsBloc>.value(value: bloc, child: const EventsView()),
            ),
          ),
          GoRoute(path: '/events/:id', builder: (_, state) => Text('event ${state.pathParameters['id']}')),
        ],
      );
      addTearDown(router.dispose);
      return tester.pumpAppScaled(
        Router(
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
        ),
        textScale: textScale,
      );
    }

    testWidgets('lists the events of the month with their duration, venue and a holiday tag', (tester) async {
      await pump(tester, EventsLoaded(november, [annual, diwali], holidaysOnly: false));
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('Annual Day'), findsOneWidget);
      expect(find.text('1 Day Event · Auditorium'), findsOneWidget);
      expect(find.text('Diwali break'), findsOneWidget);
      expect(find.text('Holiday'), findsOneWidget);
    });

    testWidgets('a tap on an event opens it', (tester) async {
      await pump(tester, EventsLoaded(november, [annual], holidaysOnly: false));
      await tester.tap(find.byKey(const ValueKey('events.item.e1')));
      await tester.pumpAndSettle();
      expect(find.text('event e1'), findsOneWidget);
    });

    testWidgets('the month stepper and the holidays filter ask for another month and for holidays only', (
      tester,
    ) async {
      await pump(tester, EventsLoaded(november, [annual], holidaysOnly: false));
      await tester.tap(find.byKey(const Key('monthStepper.next')));
      verify(() => bloc.add(EventsMonthChosen(DateTime(2026, 12)))).called(1);
      await tester.tap(find.byKey(const Key('monthStepper.previous')));
      verify(() => bloc.add(EventsMonthChosen(DateTime(2026, 10)))).called(1);
      await tester.tap(find.text('Holidays'));
      verify(() => bloc.add(const EventsHolidaysOnlyChosen(holidaysOnly: true))).called(1);
    });

    testWidgets('an empty month says so, in words for the holidays filter too', (tester) async {
      await pump(tester, EventsLoaded(november, const [], holidaysOnly: false));
      expect(find.text('No events this month'), findsOneWidget);
    });

    testWidgets('an empty month of holidays says so', (tester) async {
      await pump(tester, EventsLoaded(november, const [], holidaysOnly: true));
      expect(find.text('No holidays this month'), findsOneWidget);
    });

    testWidgets('shows a placeholder while it loads', (tester) async {
      await pump(tester, EventsLoading(november, holidaysOnly: false));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('says why it failed, and reads the month again on Try again', (tester) async {
      await pump(tester, EventsFailed(november, const ApiFailure.network(), holidaysOnly: false));
      expect(find.byKey(const Key('events.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const EventsRequested())).called(1);
    });

    testWidgets('says plainly when the person may not read the events, with no retry', (tester) async {
      await pump(
        tester,
        EventsFailed(november, const ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x'), holidaysOnly: false),
      );
      expect(find.byKey(const Key('events.forbidden')), findsOneWidget);
      expect(find.byKey(const Key('events.failed')), findsNothing);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('says that a blocked child has no access, with no retry', (tester) async {
      await pump(
        tester,
        EventsFailed(
          november,
          const ApiFailure(statusCode: 403, code: 'CHILD_ACCESS_BLOCKED', message: 'x'),
          holidaysOnly: false,
        ),
      );
      expect(find.text("Access to this child's information is blocked. Contact the school."), findsOneWidget);
    });

    testWidgets('reads whole at a large text scale on a small phone', (tester) async {
      final long = schoolEvent(
        id: 'e3',
        title: 'Inter-Institutional Science Exhibition and Innovation Showcase',
        venue: 'Sri Vidya Educational Society Senior Secondary School Auditorium',
      );
      await pump(tester, EventsLoaded(november, [long, diwali], holidaysOnly: false), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
    });
  });

  group('event detail', () {
    late _MockEventBloc bloc;
    setUpAll(() => registerFallbackValue(const EventRequested()));
    setUp(() => bloc = _MockEventBloc());

    Future<void> pump(WidgetTester tester, EventState state, {double textScale = 1}) {
      when(() => bloc.state).thenReturn(state);
      return tester.pumpAppScaled(
        BlocProvider<EventBloc>.value(value: bloc, child: const EventView(owner: false)),
        textScale: textScale,
      );
    }

    testWidgets('shows what the event is, when, where and who is told', (tester) async {
      await pump(tester, EventLoaded(annual));
      expect(find.text('Annual Day'), findsOneWidget);
      expect(find.text('Prizes and a play.'), findsOneWidget);
      expect(find.text('20-11-2026'), findsOneWidget);
      expect(find.text('Auditorium'), findsOneWidget);
      expect(find.text('Everyone'), findsOneWidget);
      expect(find.text('The whole Society'), findsOneWidget);
      expect(find.text('Holiday'), findsNothing);
    });

    testWidgets('a holiday says its kind, who it is for and which classes', (tester) async {
      await pump(tester, EventLoaded(diwali));
      expect(find.text('Holiday'), findsOneWidget);
      expect(find.text('20-11-2026 to 22-11-2026'), findsOneWidget);
      expect(find.text('Vacation'), findsOneWidget);
      expect(find.text('Students and staff'), findsOneWidget);
      expect(find.text('2 classes'), findsOneWidget);
    });

    testWidgets('a holiday for every class says so', (tester) async {
      await pump(
        tester,
        EventLoaded(schoolEvent(isHoliday: true, forStudents: true, holidayType: HolidayType.publicHoliday)),
      );
      expect(find.text('Every class'), findsOneWidget);
      expect(find.text('Students'), findsOneWidget);
    });

    testWidgets('a holiday for staff alone has no classes row', (tester) async {
      await pump(
        tester,
        EventLoaded(schoolEvent(isHoliday: true, forStaff: true, holidayType: HolidayType.optional)),
      );
      expect(find.text('Staff'), findsWidgets);
      expect(find.text('Classes'), findsNothing);
      expect(find.text('Every class'), findsNothing);
      expect(find.text('Optional'), findsOneWidget);
    });

    testWidgets('says plainly when the person may not read the event, with no retry', (tester) async {
      await pump(tester, const EventFailed(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
      expect(find.byKey(const Key('event.forbidden')), findsOneWidget);
      expect(find.byKey(const Key('event.failed')), findsNothing);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('an event that is gone says so', (tester) async {
      await pump(tester, const EventFailed(ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')));
      expect(find.text('This event is no longer available.'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('says why it failed, and reads again on Try again', (tester) async {
      await pump(tester, const EventFailed(ApiFailure.network()));
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const EventRequested())).called(1);
    });

    testWidgets('shows a placeholder while it loads', (tester) async {
      await pump(tester, const EventLoading());
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('reads whole at a large text scale on a small phone', (tester) async {
      final long = schoolEvent(
        title: 'Inter-Institutional Science Exhibition and Innovation Showcase',
        description: 'Sri Vidya Educational Society Senior Secondary School invites every family.',
        venue: 'Sri Vidya Educational Society Senior Secondary School Auditorium',
      );
      await pump(tester, EventLoaded(long), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
    });
  });
}
