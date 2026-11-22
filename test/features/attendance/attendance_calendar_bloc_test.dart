import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/bloc/attendance_calendar_bloc.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/bloc/day_detail_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/attendance.dart';
import '../../helpers/mocks.dart';

ApiFailure refusal(String code, {int status = 422}) => ApiFailure(statusCode: status, code: code, message: code);

void main() {
  late MockAttendanceRepository repository;
  setUp(() {
    repository = MockAttendanceRepository();
    when(() => repository.calendar('s1', '2026-11')).thenAnswer((_) async => november);
  });

  /// It is the 17th of November 2026 in IST (04:00 UTC), and 31 December 23:00 UTC is already 1 January in IST.
  AttendanceCalendarBloc build({DateTime? now}) =>
      AttendanceCalendarBloc(repository, 's1', clock: () => now ?? DateTime.utc(2026, 11, 17, 4));

  group('the calendar', () {
    blocTest<AttendanceCalendarBloc, AttendanceCalendarState>(
      'opens on the month of today and reads it',
      build: build,
      act: (bloc) => bloc.add(const AttendanceCalendarStarted()),
      expect: () => [
        AttendanceCalendarLoading(DateTime(2026, 11)),
        AttendanceCalendarReady(DateTime(2026, 11), november),
      ],
    );

    blocTest<AttendanceCalendarBloc, AttendanceCalendarState>(
      'takes the month of today in IST, not in UTC',
      setUp: () => when(() => repository.calendar('s1', '2027-01')).thenAnswer((_) async => november),
      build: () => build(now: DateTime.utc(2026, 12, 31, 20)),
      act: (bloc) => bloc.add(const AttendanceCalendarStarted()),
      verify: (_) => verify(() => repository.calendar('s1', '2027-01')).called(1),
    );

    blocTest<AttendanceCalendarBloc, AttendanceCalendarState>(
      'steps to another month and reads it, whatever day of it was given',
      setUp: () => when(() => repository.calendar('s1', '2026-10')).thenAnswer((_) async => november),
      build: build,
      act: (bloc) => bloc.add(AttendanceCalendarMonthChosen(DateTime(2026, 10, 15))),
      expect: () => [
        AttendanceCalendarLoading(DateTime(2026, 10)),
        AttendanceCalendarReady(DateTime(2026, 10), november),
      ],
    );

    blocTest<AttendanceCalendarBloc, AttendanceCalendarState>(
      'keeps the month when it cannot be read, so the stepper can move on, and reads it again on retry',
      setUp: () {
        var calls = 0;
        when(() => repository.calendar('s1', '2027-01')).thenAnswer((_) async {
          if (++calls == 1) throw refusal('OUTSIDE_ACADEMIC_YEAR');
          return november;
        });
      },
      build: build,
      act: (bloc) async {
        bloc.add(AttendanceCalendarMonthChosen(DateTime(2027)));
        await bloc.stream.firstWhere((state) => state is AttendanceCalendarFailed);
        bloc.add(const AttendanceCalendarRetried());
      },
      expect: () => [
        AttendanceCalendarLoading(DateTime(2027)),
        AttendanceCalendarFailed(DateTime(2027), refusal('OUTSIDE_ACADEMIC_YEAR')),
        AttendanceCalendarLoading(DateTime(2027)),
        AttendanceCalendarReady(DateTime(2027), november),
      ],
    );
  });

  group('a day', () {
    blocTest<DayDetailBloc, DayDetailState>(
      'is read when asked for',
      setUp: () => when(() => repository.dayDetail('s1', '2026-11-03')).thenAnswer((_) async => absentOnThe3rd),
      build: () => DayDetailBloc(repository, 's1', '2026-11-03'),
      act: (bloc) => bloc.add(const DayDetailRequested()),
      expect: () => [const DayDetailLoading(), DayDetailLoaded(absentOnThe3rd)],
    );

    blocTest<DayDetailBloc, DayDetailState>(
      'keeps the failure for the sheet',
      setUp: () => when(() => repository.dayDetail('s1', '2026-11-03')).thenThrow(refusal('NOT_ASSIGNED', status: 403)),
      build: () => DayDetailBloc(repository, 's1', '2026-11-03'),
      act: (bloc) => bloc.add(const DayDetailRequested()),
      expect: () => [const DayDetailLoading(), DayDetailFailed(refusal('NOT_ASSIGNED', status: 403))],
    );
  });
}
