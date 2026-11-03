import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/bloc/academic_year_form_bloc.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/bloc/academic_years_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/mocks.dart';

const _locked = ApiFailure(statusCode: 409, code: 'CURRENT_YEAR_LOCKED', message: 'x');

void main() {
  late MockAcademicYearsRepository repository;
  setUp(() => repository = MockAcademicYearsRepository());

  group('AcademicYearsBloc', () {
    AcademicYearsBloc build() => AcademicYearsBloc(repository, 'i1');

    blocTest<AcademicYearsBloc, ListState<AcademicYear>>(
      'loads the years of its Institution',
      build: build,
      setUp: () => when(() => repository.years('i1')).thenAnswer((_) async => [currentYear, earlierYear]),
      act: (bloc) => bloc.add(const ListRequested()),
      expect: () => [
        const ListLoading<AcademicYear>(),
        const ListLoaded<AcademicYear>([currentYear, earlierYear]),
      ],
    );

    blocTest<AcademicYearsBloc, ListState<AcademicYear>>(
      'keeps the failure for the screen, and loads again on retry',
      build: build,
      setUp: () {
        var calls = 0;
        when(() => repository.years('i1')).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [currentYear];
        });
      },
      act: (bloc) async {
        bloc.add(const ListRequested());
        await bloc.stream.firstWhere((state) => state is ListFailed<AcademicYear>);
        bloc.add(const ListRequested());
      },
      expect: () => [
        const ListLoading<AcademicYear>(),
        const ListFailed<AcademicYear>(ApiFailure.network()),
        const ListLoading<AcademicYear>(),
        const ListLoaded<AcademicYear>([currentYear]),
      ],
    );

    blocTest<AcademicYearsBloc, ListState<AcademicYear>>(
      'makes a year current, then reads the years again, saying what was done',
      build: build,
      setUp: () {
        var made = false;
        when(() => repository.years('i1')).thenAnswer(
          (_) async => made ? [earlierYearMadeCurrent, currentYearDemoted] : [currentYear, earlierYear],
        );
        when(() => repository.makeCurrent(earlierYear)).thenAnswer((_) async {
          made = true;
          return earlierYear;
        });
      },
      act: (bloc) async {
        bloc.add(const ListRequested());
        await bloc.stream.firstWhere((state) => state is ListLoaded<AcademicYear>);
        bloc.add(const AcademicYearMadeCurrent(earlierYear));
      },
      skip: 2,
      expect: () => [
        const ListLoaded<AcademicYear>([currentYear, earlierYear], busyId: 'y0'),
        isA<ListLoaded<AcademicYear>>()
            .having((state) => state.notice, 'notice', AcademicYearsNotice.madeCurrent)
            .having((state) => state.changed, 'changed', earlierYear)
            .having((state) => state.items.map((year) => year.isCurrent), 'current marks', [true, false]),
      ],
    );

    blocTest<AcademicYearsBloc, ListState<AcademicYear>>(
      'deactivates a year, then reads the years again',
      build: build,
      setUp: () {
        var gone = false;
        when(() => repository.years('i1')).thenAnswer((_) async => gone ? [currentYear] : [currentYear, earlierYear]);
        when(() => repository.deactivate('y0')).thenAnswer((_) async => gone = true);
      },
      act: (bloc) async {
        bloc.add(const ListRequested());
        await bloc.stream.firstWhere((state) => state is ListLoaded<AcademicYear>);
        bloc.add(const AcademicYearDeactivated(earlierYear));
      },
      skip: 2,
      expect: () => [
        const ListLoaded<AcademicYear>([currentYear, earlierYear], busyId: 'y0'),
        const ListLoaded<AcademicYear>([currentYear], notice: AcademicYearsNotice.deactivated, changed: earlierYear),
      ],
    );

    blocTest<AcademicYearsBloc, ListState<AcademicYear>>(
      'keeps the years and says why when a change is refused, with the list read again',
      build: build,
      setUp: () {
        when(() => repository.years('i1')).thenAnswer((_) async => [currentYear, earlierYear]);
        when(() => repository.deactivate('y1')).thenThrow(_locked);
      },
      act: (bloc) async {
        bloc.add(const ListRequested());
        await bloc.stream.firstWhere((state) => state is ListLoaded<AcademicYear>);
        bloc.add(const AcademicYearDeactivated(currentYear));
      },
      skip: 2,
      expect: () => [
        const ListLoaded<AcademicYear>([currentYear, earlierYear], busyId: 'y1'),
        const ListLoaded<AcademicYear>([currentYear, earlierYear], actionFailure: _locked),
      ],
      verify: (_) => verify(() => repository.years('i1')).called(2),
    );

    blocTest<AcademicYearsBloc, ListState<AcademicYear>>(
      'fails the screen when the list cannot be read again after a change',
      build: build,
      setUp: () {
        var calls = 0;
        when(() => repository.years('i1')).thenAnswer((_) async {
          if (++calls == 2) throw const ApiFailure.network();
          return [currentYear, earlierYear];
        });
        when(() => repository.deactivate('y0')).thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const ListRequested());
        await bloc.stream.firstWhere((state) => state is ListLoaded<AcademicYear>);
        bloc.add(const AcademicYearDeactivated(earlierYear));
      },
      skip: 2,
      expect: () => [
        const ListLoaded<AcademicYear>([currentYear, earlierYear], busyId: 'y0'),
        const ListFailed<AcademicYear>(ApiFailure.network()),
      ],
    );

    blocTest<AcademicYearsBloc, ListState<AcademicYear>>(
      'does not start a second change while one is on its way',
      build: build,
      setUp: () {
        when(() => repository.years('i1')).thenAnswer((_) async => [currentYear, earlierYear]);
        when(() => repository.deactivate(any()))
            .thenAnswer((_) => Future<void>.delayed(const Duration(milliseconds: 10)));
      },
      act: (bloc) async {
        bloc.add(const ListRequested());
        await bloc.stream.firstWhere((state) => state is ListLoaded<AcademicYear>);
        bloc
          ..add(const AcademicYearDeactivated(earlierYear))
          ..add(const AcademicYearDeactivated(earlierYear));
      },
      verify: (_) => verify(() => repository.deactivate('y0')).called(1),
      expect: () => anything,
    );
  });

  group('AcademicYearFormBloc', () {
    const fields = AcademicYearFields(name: ' 2026-2027 ', startDate: '2026-06-01', endDate: '2027-03-31');

    blocTest<AcademicYearFormBloc, AcademicYearFormState>(
      'adds a year with the name trimmed',
      build: () => AcademicYearFormBloc(repository, 'i1'),
      setUp: () => when(
        () => repository.create('i1', name: '2026-2027', startDate: '2026-06-01', endDate: '2027-03-31'),
      ).thenAnswer((_) async => currentYear),
      act: (bloc) => bloc.add(const AcademicYearFormSubmitted(fields)),
      expect: () => [const AcademicYearFormEditing(saving: true), const AcademicYearFormSaved(currentYear)],
    );

    blocTest<AcademicYearFormBloc, AcademicYearFormState>(
      'changes the year it was opened on, with the version it read',
      build: () => AcademicYearFormBloc(repository, 'i1', existing: earlierYear),
      setUp: () => when(
        () => repository.update(earlierYear, name: '2026-2027', startDate: '2026-06-01', endDate: '2027-03-31'),
      ).thenAnswer((_) async => currentYear),
      act: (bloc) => bloc.add(const AcademicYearFormSubmitted(fields)),
      expect: () => [const AcademicYearFormEditing(saving: true), const AcademicYearFormSaved(currentYear)],
      verify: (_) => verifyNever(
        () => repository.create(
          any(),
          name: any(named: 'name'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ),
    );

    blocTest<AcademicYearFormBloc, AcademicYearFormState>(
      'keeps the form, with the refusal, so it can be fixed and sent again',
      build: () => AcademicYearFormBloc(repository, 'i1'),
      setUp: () => when(
        () => repository.create(
          any(),
          name: any(named: 'name'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenThrow(const ApiFailure(statusCode: 409, code: 'YEAR_OVERLAP', message: 'x')),
      act: (bloc) => bloc.add(const AcademicYearFormSubmitted(fields)),
      expect: () => [
        const AcademicYearFormEditing(saving: true),
        const AcademicYearFormEditing(
          failure: ApiFailure(statusCode: 409, code: 'YEAR_OVERLAP', message: 'x'),
        ),
      ],
    );

    blocTest<AcademicYearFormBloc, AcademicYearFormState>(
      'does not send twice while a save is on its way',
      build: () => AcademicYearFormBloc(repository, 'i1'),
      setUp: () =>
          when(
            () => repository.create(
              any(),
              name: any(named: 'name'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            ),
          ).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return currentYear;
          }),
      act: (bloc) => bloc
        ..add(const AcademicYearFormSubmitted(fields))
        ..add(const AcademicYearFormSubmitted(fields)),
      verify: (_) => verify(
        () => repository.create(
          any(),
          name: any(named: 'name'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).called(1),
      expect: () => anything,
    );
  });
}
