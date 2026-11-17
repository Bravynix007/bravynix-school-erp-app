import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/event_bloc.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/events_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/events.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockEventsRepository repository;
  final today = DateTime(2026, 11, 17);
  final november = DateTime(2026, 11);
  final december = DateTime(2026, 12);
  final annual = schoolEvent();

  setUp(() => repository = MockEventsRepository());

  void answer(DateTime from, DateTime to, List<Object> events, {bool holidaysOnly = false, String? studentId}) => when(
    () => repository.events(from: from, to: to, holidaysOnly: holidaysOnly, studentId: studentId),
  ).thenAnswer((_) async => events.cast());

  group('EventsBloc', () {
    blocTest<EventsBloc, EventsState>(
      'reads the month of today, for the child a parent is viewing',
      build: () {
        answer(november, DateTime(2026, 11, 30), [annual], studentId: 's1');
        return EventsBloc(repository, today: today, studentId: 's1');
      },
      act: (bloc) => bloc.add(const EventsRequested()),
      expect: () => [
        EventsLoading(november, holidaysOnly: false),
        EventsLoaded(november, [annual], holidaysOnly: false),
      ],
    );

    blocTest<EventsBloc, EventsState>(
      'stepping to another month reads that month, to its last day',
      build: () {
        answer(december, DateTime(2026, 12, 31), []);
        return EventsBloc(repository, today: today);
      },
      act: (bloc) => bloc.add(EventsMonthChosen(DateTime(2026, 12, 15))),
      expect: () => [
        EventsLoading(december, holidaysOnly: false),
        EventsLoaded(december, const [], holidaysOnly: false),
      ],
    );

    blocTest<EventsBloc, EventsState>(
      'the holidays filter keeps the month and reads only holidays',
      build: () {
        answer(november, DateTime(2026, 11, 30), [], holidaysOnly: true);
        return EventsBloc(repository, today: today);
      },
      act: (bloc) => bloc.add(const EventsHolidaysOnlyChosen(holidaysOnly: true)),
      expect: () => [
        EventsLoading(november, holidaysOnly: true),
        EventsLoaded(november, const [], holidaysOnly: true),
      ],
    );

    blocTest<EventsBloc, EventsState>(
      'says why the month could not be read, and reads it again on Try again',
      build: () {
        var calls = 0;
        when(
          () => repository.events(
            from: any(named: 'from'),
            to: any(named: 'to'),
            holidaysOnly: any(named: 'holidaysOnly'),
            studentId: any(named: 'studentId'),
          ),
        ).thenAnswer((_) async => calls++ == 0 ? throw const ApiFailure.network() : [annual]);
        return EventsBloc(repository, today: today);
      },
      act: (bloc) => bloc
        ..add(const EventsRequested())
        ..add(const EventsRequested()),
      wait: const Duration(milliseconds: 20),
      expect: () => [
        EventsLoading(november, holidaysOnly: false),
        EventsFailed(november, const ApiFailure.network(), holidaysOnly: false),
        EventsLoading(november, holidaysOnly: false),
        EventsLoaded(november, [annual], holidaysOnly: false),
      ],
    );

    blocTest<EventsBloc, EventsState>(
      'an answer for the month left behind is dropped',
      build: () {
        when(
          () => repository.events(
            from: november,
            to: DateTime(2026, 11, 30),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return [annual];
        });
        answer(december, DateTime(2026, 12, 31), []);
        return EventsBloc(repository, today: today);
      },
      act: (bloc) => bloc
        ..add(const EventsRequested())
        ..add(EventsMonthChosen(december)),
      wait: const Duration(milliseconds: 60),
      expect: () => [
        EventsLoading(november, holidaysOnly: false),
        EventsLoading(december, holidaysOnly: false),
        EventsLoaded(december, const [], holidaysOnly: false),
      ],
    );
  });

  group('EventBloc', () {
    blocTest<EventBloc, EventState>(
      'reads the event by its ID, for the child a parent is viewing',
      build: () {
        when(() => repository.event('e1', studentId: 's1')).thenAnswer((_) async => annual);
        return EventBloc(repository, 'e1', studentId: 's1');
      },
      act: (bloc) => bloc.add(const EventRequested()),
      expect: () => [const EventLoading(), EventLoaded(annual)],
    );

    blocTest<EventBloc, EventState>(
      'says why it could not be read',
      build: () {
        when(() => repository.event(any(), studentId: any(named: 'studentId'))).thenThrow(
          const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x'),
        );
        return EventBloc(repository, 'e1');
      },
      act: (bloc) => bloc.add(const EventRequested()),
      expect: () => [
        const EventLoading(),
        const EventFailed(ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')),
      ],
    );
  });
}
