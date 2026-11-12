import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_filters_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/students_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/classes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/sections.dart';
import '../../helpers/students.dart';

const _down = ApiFailure(statusCode: 503, code: 'UNAVAILABLE', message: 'x');
const _gone = ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x');

typedef _Loaded = PagedListLoaded<StudentListEntry>;

void main() {
  late MockStudentsRepository students;
  late MockAcademicYearsRepository years;
  late MockClassesRepository classes;
  late MockSectionsRepository sections;
  late SectionOptionsSource options;

  setUpAll(() {
    registerFallbackValue(const StudentFilter());
    registerFallbackValue(LeavingReason.left);
  });
  setUp(() {
    students = MockStudentsRepository();
    years = MockAcademicYearsRepository();
    classes = MockClassesRepository();
    sections = MockSectionsRepository();
    when(() => years.years('i1')).thenAnswer((_) async => [earlierYear, currentYear]);
    when(() => classes.classes('i1')).thenAnswer((_) async => [class1, pucClass]);
    when(() => sections.sections('k1')).thenAnswer((_) async => [sectionA, sectionB]);
    options = SectionOptionsSource(years: years, classes: classes, sections: sections);
  });

  group('StudentsBloc', () {
    StudentsBloc build() => StudentsBloc(students, options, 'i1');

    void list(List<StudentSummary> rows, {int totalPages = 1}) => when(
      () => students.students(
        'i1',
        page: any(named: 'page'),
        query: any(named: 'query'),
        filter: any(named: 'filter'),
      ),
    ).thenAnswer((_) async => ItemsPage(rows, page: 1, totalPages: totalPages));

    blocTest<StudentsBloc, PagedListState<StudentListEntry>>(
      'reads the first page of its Institution with the name of the class and section of each row',
      setUp: () => list([asha, bala], totalPages: 2),
      build: build,
      act: (bloc) => bloc.add(const PagedListRequested()),
      expect: () => [
        const PagedListLoading<StudentListEntry>(),
        const _Loaded(
          [
            StudentListEntry(asha, placeName: 'Class 1 · Section A'),
            StudentListEntry(bala),
          ],
          hasMore: true,
        ),
      ],
    );

    blocTest<StudentsBloc, PagedListState<StudentListEntry>>(
      'passes the search and the page on, and names the rows of the next page',
      setUp: () {
        when(
          () => students.students('i1', query: 'as'),
        ).thenAnswer((_) async => const ItemsPage([asha], page: 1, totalPages: 2));
        when(
          () => students.students('i1', page: 2, query: 'as'),
        ).thenAnswer((_) async => const ItemsPage([bala], page: 2, totalPages: 2));
      },
      build: build,
      act: (bloc) async {
        bloc.add(const PagedListSearched('as'));
        await bloc.stream.firstWhere((state) => state is _Loaded);
        bloc.add(const PagedListMoreRequested());
      },
      skip: 2,
      expect: () => [
        const _Loaded([ashaEntry], query: 'as', hasMore: true, loadingMore: true),
        const _Loaded([ashaEntry, balaEntry], query: 'as', page: 2),
      ],
    );

    blocTest<StudentsBloc, PagedListState<StudentListEntry>>(
      'reads the first page again for a filter, and keeps the filter for the pages and the search after it',
      setUp: () {
        when(
          () => students.students('i1', filter: const StudentFilter(classId: 'k1')),
        ).thenAnswer((_) async => const ItemsPage([asha], page: 1, totalPages: 1));
        when(
          () => students.students(
            'i1',
            query: 'as',
            filter: const StudentFilter(classId: 'k1'),
          ),
        ).thenAnswer((_) async => const ItemsPage([asha], page: 1, totalPages: 1));
      },
      build: build,
      act: (bloc) async {
        bloc.add(const StudentsFiltered(StudentFilter(classId: 'k1')));
        await bloc.stream.firstWhere((state) => state is _Loaded);
        bloc.add(const PagedListSearched('as'));
      },
      expect: () => [
        const PagedListLoading<StudentListEntry>(),
        const _Loaded([ashaEntry]),
        const PagedListLoading<StudentListEntry>(),
        const _Loaded([ashaEntry], query: 'as'),
      ],
    );

    blocTest<StudentsBloc, PagedListState<StudentListEntry>>(
      'does not read again for the filter it has',
      setUp: () => list([asha]),
      build: build,
      act: (bloc) => bloc.add(const StudentsFiltered(StudentFilter())),
      expect: () => <PagedListState<StudentListEntry>>[],
      verify: (_) => verifyNever(
        () => students.students(
          'i1',
          page: any(named: 'page'),
          query: any(named: 'query'),
          filter: any(named: 'filter'),
        ),
      ),
    );

    blocTest<StudentsBloc, PagedListState<StudentListEntry>>(
      'leaves a filter until the deactivation that is going has answered',
      setUp: () {
        list([asha]);
        when(() => students.deactivate(any(), any())).thenAnswer((_) async {});
      },
      build: build,
      act: (bloc) async {
        bloc.add(const PagedListRequested());
        await bloc.stream.firstWhere((state) => state is _Loaded);
        bloc.add(const StudentDeactivated(ashaEntry, LeavingReason.left));
        await bloc.stream.firstWhere((state) => state is _Loaded && state.busyId != null);
        bloc.add(const StudentsFiltered(StudentFilter(classId: 'k1')));
      },
      skip: 2,
      expect: () => [
        const _Loaded([ashaEntry], busyId: 'p1'),
        const _Loaded([ashaEntry], changed: ashaEntry),
      ],
      verify: (_) => verifyNever(() => students.students('i1', filter: const StudentFilter(classId: 'k1'))),
    );

    blocTest<StudentsBloc, PagedListState<StudentListEntry>>(
      'deactivates a student by ID with the reason, then reads the first page again, saying which one went',
      setUp: () {
        var gone = false;
        when(
          () => students.students(
            'i1',
            query: any(named: 'query'),
            filter: any(named: 'filter'),
          ),
        ).thenAnswer((_) async => ItemsPage(gone ? [bala] : [asha, bala], page: 1, totalPages: 1));
        when(() => students.deactivate('p1', LeavingReason.mistake)).thenAnswer((_) async => gone = true);
      },
      build: build,
      act: (bloc) async {
        bloc.add(const PagedListRequested());
        await bloc.stream.firstWhere((state) => state is _Loaded);
        bloc.add(const StudentDeactivated(ashaEntry, LeavingReason.mistake));
      },
      skip: 2,
      expect: () => [
        const _Loaded([ashaEntry, balaEntry], busyId: 'p1'),
        const _Loaded([balaEntry], changed: ashaEntry),
      ],
    );

    blocTest<StudentsBloc, PagedListState<StudentListEntry>>(
      'says why a deactivation was refused, and keeps the list',
      setUp: () {
        list([asha]);
        when(() => students.deactivate('p1', LeavingReason.left)).thenThrow(_gone);
      },
      build: build,
      act: (bloc) async {
        bloc.add(const PagedListRequested());
        await bloc.stream.firstWhere((state) => state is _Loaded);
        bloc.add(const StudentDeactivated(ashaEntry, LeavingReason.left));
      },
      skip: 2,
      expect: () => [
        const _Loaded([ashaEntry], busyId: 'p1'),
        const _Loaded([ashaEntry], actionFailure: _gone),
      ],
    );

    blocTest<StudentsBloc, PagedListState<StudentListEntry>>(
      'fails when the sections cannot be read, and reads them again on Try again',
      setUp: () {
        list([asha]);
        var calls = 0;
        when(() => years.years('i1')).thenAnswer((_) async {
          if (calls++ == 0) throw _down;
          return [currentYear];
        });
      },
      build: build,
      act: (bloc) async {
        bloc.add(const PagedListRequested());
        await bloc.stream.firstWhere((state) => state is PagedListFailed<StudentListEntry>);
        bloc.add(const PagedListRequested());
      },
      expect: () => [
        const PagedListLoading<StudentListEntry>(),
        const PagedListFailed<StudentListEntry>(_down),
        const PagedListLoading<StudentListEntry>(),
        const _Loaded([ashaEntry]),
      ],
    );
  });

  group('StudentFiltersBloc', () {
    StudentFiltersBloc build() => StudentFiltersBloc(options, 'i1');

    blocTest<StudentFiltersBloc, StudentFiltersState>(
      'reads the years, classes and sections once, with no filter chosen',
      build: build,
      act: (bloc) => bloc.add(const StudentFiltersStarted()),
      expect: () => [
        const StudentFiltersLoading(),
        isA<StudentFiltersReady>()
            .having((s) => s.filter.isEmpty, 'no filter', true)
            .having((s) => s.options.years, 'years', [earlierYear, currentYear])
            .having((s) => s.sections.map((section) => section.id), 'sections', ['e1', 'e2']),
      ],
    );

    blocTest<StudentFiltersBloc, StudentFiltersState>(
      'fails when the options cannot be read',
      setUp: () => when(() => years.years('i1')).thenThrow(_down),
      build: build,
      act: (bloc) => bloc.add(const StudentFiltersStarted()),
      expect: () => [const StudentFiltersLoading(), const StudentFiltersFailed(_down)],
    );

    blocTest<StudentFiltersBloc, StudentFiltersState>(
      'keeps the year, the class and the section chosen apart',
      build: build,
      act: (bloc) async {
        bloc.add(const StudentFiltersStarted());
        await bloc.stream.firstWhere((state) => state is StudentFiltersReady);
        bloc
          ..add(const StudentFiltersYearChosen('y1'))
          ..add(const StudentFiltersClassChosen('k1'))
          ..add(const StudentFiltersSectionChosen('e2'));
      },
      skip: 2,
      expect: () => [
        isA<StudentFiltersReady>().having((s) => s.filter, 'filter', const StudentFilter(academicYearId: 'y1')),
        isA<StudentFiltersReady>().having(
          (s) => s.filter,
          'filter',
          const StudentFilter(academicYearId: 'y1', classId: 'k1'),
        ),
        isA<StudentFiltersReady>().having(
          (s) => s.filter,
          'filter',
          const StudentFilter(academicYearId: 'y1', classId: 'k1', sectionId: 'e2'),
        ),
      ],
    );

    blocTest<StudentFiltersBloc, StudentFiltersState>(
      'offers only the sections of the class chosen, and lets go a section of another class',
      build: build,
      act: (bloc) async {
        bloc.add(const StudentFiltersStarted());
        await bloc.stream.firstWhere((state) => state is StudentFiltersReady);
        bloc
          ..add(const StudentFiltersClassChosen('k1'))
          ..add(const StudentFiltersSectionChosen('e2'))
          ..add(const StudentFiltersClassChosen('k9'));
      },
      skip: 2,
      expect: () => [
        isA<StudentFiltersReady>().having((s) => s.sections.map((section) => section.id), 'sections', ['e1', 'e2']),
        isA<StudentFiltersReady>().having((s) => s.filter.sectionId, 'section', 'e2'),
        isA<StudentFiltersReady>()
            .having((s) => s.filter, 'filter', const StudentFilter(classId: 'k9'))
            .having((s) => s.sections, 'sections', isEmpty),
      ],
    );

    blocTest<StudentFiltersBloc, StudentFiltersState>(
      'a section chosen with no class also chooses its class, and Any section keeps the class',
      build: build,
      act: (bloc) async {
        bloc.add(const StudentFiltersStarted());
        await bloc.stream.firstWhere((state) => state is StudentFiltersReady);
        bloc
          ..add(const StudentFiltersSectionChosen('e1'))
          ..add(const StudentFiltersSectionChosen(null));
      },
      skip: 2,
      expect: () => [
        isA<StudentFiltersReady>().having(
          (s) => s.filter,
          'filter',
          const StudentFilter(classId: 'k1', sectionId: 'e1'),
        ),
        isA<StudentFiltersReady>().having((s) => s.filter, 'filter', const StudentFilter(classId: 'k1')),
      ],
    );

    blocTest<StudentFiltersBloc, StudentFiltersState>(
      'clears every filter',
      build: build,
      act: (bloc) async {
        bloc.add(const StudentFiltersStarted());
        await bloc.stream.firstWhere((state) => state is StudentFiltersReady);
        bloc
          ..add(const StudentFiltersYearChosen('y1'))
          ..add(const StudentFiltersCleared());
      },
      skip: 3,
      expect: () => [isA<StudentFiltersReady>().having((s) => s.filter.isEmpty, 'empty', true)],
    );

    blocTest<StudentFiltersBloc, StudentFiltersState>(
      'ignores a choice before the options are read',
      build: build,
      act: (bloc) => bloc.add(const StudentFiltersYearChosen('y1')),
      expect: () => <StudentFiltersState>[],
    );
  });
}
