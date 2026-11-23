import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slot.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/bloc/time_slot_form_bloc.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/bloc/time_slots_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/time_slots.dart';

const _inUse = ApiFailure(statusCode: 409, code: 'TIME_SLOT_IN_USE', message: 'x');

void main() {
  late MockTimeSlotsRepository repository;
  setUp(() => repository = MockTimeSlotsRepository());

  group('TimeSlotsBloc', () {
    TimeSlotsBloc build() => TimeSlotsBloc(repository, 'i1');

    blocTest<TimeSlotsBloc, ListState<TimeSlot>>(
      'loads the periods of its Institution',
      build: build,
      setUp: () => when(() => repository.slots('i1')).thenAnswer((_) async => [firstPeriod, lunch]),
      act: (bloc) => bloc.add(const ListRequested()),
      expect: () => [
        const ListLoading<TimeSlot>(),
        const ListLoaded<TimeSlot>([firstPeriod, lunch]),
      ],
    );

    blocTest<TimeSlotsBloc, ListState<TimeSlot>>(
      'keeps the failure for the screen, and loads again on retry',
      build: build,
      setUp: () {
        var calls = 0;
        when(() => repository.slots('i1')).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [firstPeriod];
        });
      },
      act: (bloc) async {
        bloc.add(const ListRequested());
        await bloc.stream.firstWhere((state) => state is ListFailed<TimeSlot>);
        bloc.add(const ListRequested());
      },
      expect: () => [
        const ListLoading<TimeSlot>(),
        const ListFailed<TimeSlot>(ApiFailure.network()),
        const ListLoading<TimeSlot>(),
        const ListLoaded<TimeSlot>([firstPeriod]),
      ],
    );

    blocTest<TimeSlotsBloc, ListState<TimeSlot>>(
      'deactivates a period, then reads the periods again',
      build: build,
      setUp: () {
        var gone = false;
        when(() => repository.slots('i1')).thenAnswer((_) async => gone ? [firstPeriod] : [firstPeriod, lunch]);
        when(() => repository.deactivate('t2')).thenAnswer((_) async => gone = true);
      },
      act: (bloc) async {
        bloc.add(const ListRequested());
        await bloc.stream.firstWhere((state) => state is ListLoaded<TimeSlot>);
        bloc.add(const TimeSlotDeactivated(lunch));
      },
      skip: 2,
      expect: () => [
        const ListLoaded<TimeSlot>([firstPeriod, lunch], busyId: 't2'),
        const ListLoaded<TimeSlot>([firstPeriod], changed: lunch),
      ],
    );

    blocTest<TimeSlotsBloc, ListState<TimeSlot>>(
      'keeps the periods and says why when a period in use is refused',
      build: build,
      setUp: () {
        when(() => repository.slots('i1')).thenAnswer((_) async => [firstPeriod, lunch]);
        when(() => repository.deactivate('t1')).thenThrow(_inUse);
      },
      act: (bloc) async {
        bloc.add(const ListRequested());
        await bloc.stream.firstWhere((state) => state is ListLoaded<TimeSlot>);
        bloc.add(const TimeSlotDeactivated(firstPeriod));
      },
      skip: 2,
      expect: () => [
        const ListLoaded<TimeSlot>([firstPeriod, lunch], busyId: 't1'),
        const ListLoaded<TimeSlot>([firstPeriod, lunch], actionFailure: _inUse),
      ],
      verify: (_) => verify(() => repository.slots('i1')).called(2),
    );
  });

  group('TimeSlotFormBloc', () {
    const fields = TimeSlotFields(
      periodNo: ' 4 ',
      label: ' Lunch ',
      startTime: '12:00',
      endTime: '12:30',
      isBreak: true,
    );

    blocTest<TimeSlotFormBloc, TimeSlotFormState>(
      'adds a period with the number read and the label trimmed',
      build: () => TimeSlotFormBloc(repository, 'i1'),
      setUp: () => when(
        () => repository.create('i1', periodNo: 4, startTime: '12:00', endTime: '12:30', isBreak: true, label: 'Lunch'),
      ).thenAnswer((_) async => lunch),
      act: (bloc) => bloc.add(const TimeSlotFormSubmitted(fields)),
      expect: () => [const TimeSlotFormEditing(saving: true), const TimeSlotFormSaved(lunch)],
    );

    blocTest<TimeSlotFormBloc, TimeSlotFormState>(
      'leaves an empty label out',
      build: () => TimeSlotFormBloc(repository, 'i1'),
      setUp: () => when(
        () => repository.create('i1', periodNo: 1, startTime: '09:00', endTime: '09:45', isBreak: false),
      ).thenAnswer((_) async => firstPeriod),
      act: (bloc) => bloc.add(
        const TimeSlotFormSubmitted(
          TimeSlotFields(periodNo: '1', label: '  ', startTime: '09:00', endTime: '09:45', isBreak: false),
        ),
      ),
      expect: () => [const TimeSlotFormEditing(saving: true), const TimeSlotFormSaved(firstPeriod)],
    );

    blocTest<TimeSlotFormBloc, TimeSlotFormState>(
      'changes the period it was opened on, with the version it read, whatever the form holds for its number',
      build: () => TimeSlotFormBloc(repository, 'i1', existing: lunch),
      setUp: () => when(
        () => repository.update(lunch, startTime: '12:05', endTime: '12:35'),
      ).thenAnswer((_) async => lunch),
      act: (bloc) => bloc.add(
        const TimeSlotFormSubmitted(
          TimeSlotFields(periodNo: '', label: '', startTime: '12:05', endTime: '12:35', isBreak: true),
        ),
      ),
      expect: () => [const TimeSlotFormEditing(saving: true), const TimeSlotFormSaved(lunch)],
      verify: (_) => verifyNever(
        () => repository.create(
          any(),
          periodNo: any(named: 'periodNo'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          isBreak: any(named: 'isBreak'),
          label: any(named: 'label'),
        ),
      ),
    );

    blocTest<TimeSlotFormBloc, TimeSlotFormState>(
      'sends a second Save while the first is on its way once only',
      build: () => TimeSlotFormBloc(repository, 'i1'),
      setUp: () =>
          when(
            () => repository.create(
              'i1',
              periodNo: 4,
              startTime: '12:00',
              endTime: '12:30',
              isBreak: true,
              label: 'Lunch',
            ),
          ).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return lunch;
          }),
      act: (bloc) {
        bloc
          ..add(const TimeSlotFormSubmitted(fields))
          ..add(const TimeSlotFormSubmitted(fields));
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [const TimeSlotFormEditing(saving: true), const TimeSlotFormSaved(lunch)],
      verify: (_) => verify(
        () => repository.create('i1', periodNo: 4, startTime: '12:00', endTime: '12:30', isBreak: true, label: 'Lunch'),
      ).called(1),
    );

    blocTest<TimeSlotFormBloc, TimeSlotFormState>(
      'names what is missing without asking the server',
      build: () => TimeSlotFormBloc(repository, 'i1'),
      act: (bloc) => bloc.add(
        const TimeSlotFormSubmitted(
          TimeSlotFields(periodNo: '', label: '', startTime: '', endTime: '', isBreak: false),
        ),
      ),
      expect: () => [
        isA<TimeSlotFormEditing>().having(
          (state) => state.failure?.fieldErrors.map((error) => error.field).toList(),
          'fields',
          ['periodNo', 'startTime', 'endTime'],
        ),
      ],
      verify: (_) => verifyNever(
        () => repository.create(
          any(),
          periodNo: any(named: 'periodNo'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          isBreak: any(named: 'isBreak'),
        ),
      ),
    );

    blocTest<TimeSlotFormBloc, TimeSlotFormState>(
      'keeps the form, with the refusal, so it can be fixed and sent again',
      build: () => TimeSlotFormBloc(repository, 'i1'),
      setUp: () => when(
        () => repository.create(
          any(),
          periodNo: any(named: 'periodNo'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          isBreak: any(named: 'isBreak'),
          label: any(named: 'label'),
        ),
      ).thenThrow(const ApiFailure(statusCode: 409, code: 'TIME_SLOT_OVERLAP', message: 'x')),
      act: (bloc) => bloc.add(const TimeSlotFormSubmitted(fields)),
      expect: () => [
        const TimeSlotFormEditing(saving: true),
        const TimeSlotFormEditing(
          failure: ApiFailure(statusCode: 409, code: 'TIME_SLOT_OVERLAP', message: 'x'),
        ),
      ],
    );
  });
}
