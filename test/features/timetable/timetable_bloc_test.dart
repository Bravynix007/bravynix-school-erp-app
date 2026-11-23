import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_week.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/bloc/timetable_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/timetable.dart';

void main() {
  late MockTimetableRepository repository;
  setUp(() => repository = MockTimetableRepository());

  blocTest<TimetableBloc, ListState<TimetableEntry>>(
    'reads the week it was made for',
    build: () => TimetableBloc(repository, const ChildWeek('s1')),
    setUp: () =>
        when(() => repository.week(const ChildWeek('s1'))).thenAnswer((_) async => [mathsMonday, scienceTuesday]),
    act: (bloc) => bloc.add(const ListRequested()),
    expect: () => [
      const ListLoading<TimetableEntry>(),
      const ListLoaded<TimetableEntry>([mathsMonday, scienceTuesday]),
    ],
  );

  blocTest<TimetableBloc, ListState<TimetableEntry>>(
    'removes an entry through TT-04, then reads the week again',
    build: () => TimetableBloc(repository, const SectionWeek('sec1')),
    setUp: () {
      var gone = false;
      when(() => repository.week(const SectionWeek('sec1')))
          .thenAnswer((_) async => gone ? [mathsMonday] : [mathsMonday, scienceTuesday]);
      when(() => repository.remove('x3')).thenAnswer((_) async => gone = true);
    },
    act: (bloc) async {
      bloc.add(const ListRequested());
      await bloc.stream.firstWhere((state) => state is ListLoaded<TimetableEntry>);
      bloc.add(const EntryRemoved(scienceTuesday));
    },
    skip: 2,
    expect: () => [
      const ListLoaded<TimetableEntry>([mathsMonday, scienceTuesday], busyId: 'x3'),
      const ListLoaded<TimetableEntry>([mathsMonday], changed: scienceTuesday),
    ],
    verify: (_) => verify(() => repository.remove('x3')).called(1),
  );

  blocTest<TimetableBloc, ListState<TimetableEntry>>(
    'keeps the week and says why when a removal is refused',
    build: () => TimetableBloc(repository, const SectionWeek('sec1')),
    setUp: () {
      when(() => repository.week(const SectionWeek('sec1'))).thenAnswer((_) async => [mathsMonday]);
      when(() => repository.remove('x1')).thenThrow(const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x'));
    },
    act: (bloc) async {
      bloc.add(const ListRequested());
      await bloc.stream.firstWhere((state) => state is ListLoaded<TimetableEntry>);
      bloc.add(const EntryRemoved(mathsMonday));
    },
    skip: 2,
    expect: () => [
      const ListLoaded<TimetableEntry>([mathsMonday], busyId: 'x1'),
      const ListLoaded<TimetableEntry>(
        [mathsMonday],
        actionFailure: ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x'),
      ),
    ],
  );

  blocTest<TimetableBloc, ListState<TimetableEntry>>(
    'keeps the failure for the screen, and reads again on retry',
    build: () => TimetableBloc(repository, const SectionWeek('sec1')),
    setUp: () {
      var calls = 0;
      when(() => repository.week(const SectionWeek('sec1'))).thenAnswer((_) async {
        if (++calls == 1) {
          throw const ApiFailure(statusCode: 403, code: 'NOT_ASSIGNED', message: 'x');
        }
        return [mathsMonday];
      });
    },
    act: (bloc) async {
      bloc.add(const ListRequested());
      await bloc.stream.firstWhere((state) => state is ListFailed<TimetableEntry>);
      bloc.add(const ListRequested());
    },
    expect: () => [
      const ListLoading<TimetableEntry>(),
      const ListFailed<TimetableEntry>(ApiFailure(statusCode: 403, code: 'NOT_ASSIGNED', message: 'x')),
      const ListLoading<TimetableEntry>(),
      const ListLoaded<TimetableEntry>([mathsMonday]),
    ],
  );
}
