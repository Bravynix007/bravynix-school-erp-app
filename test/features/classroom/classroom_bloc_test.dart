import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/classroom/domain/classroom.dart';
import 'package:bravynix_school_erp/features/classroom/presentation/bloc/classroom_bloc.dart';
import 'package:bravynix_school_erp/features/classroom/presentation/bloc/classroom_student_bloc.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/classes.dart';
import '../../helpers/classroom.dart';
import '../../helpers/mocks.dart';
import '../../helpers/sections.dart';

const _notAssigned = ApiFailure(statusCode: 403, code: 'NOT_ASSIGNED', message: 'x');
typedef _Loaded = PagedListLoaded<ClassroomEntry>;

void main() {
  late MockClassroomRepository classroom;
  late SectionOptionsSource options;

  setUp(() {
    classroom = MockClassroomRepository();
    final years = MockAcademicYearsRepository();
    final classes = MockClassesRepository();
    final sections = MockSectionsRepository();
    when(() => years.years('i1')).thenAnswer((_) async => [currentYear]);
    when(() => classes.classes('i1')).thenAnswer((_) async => [class1]);
    when(() => sections.sections('k1')).thenAnswer((_) async => [sectionA]);
    options = SectionOptionsSource(years: years, classes: classes, sections: sections);
  });

  group('ClassroomBloc', () {
    blocTest<ClassroomBloc, PagedListState<ClassroomEntry>>(
      'reads the first page of its Institution with the name of the section of each row',
      setUp: () => when(
        () => classroom.students('i1'),
      ).thenAnswer((_) async => const ItemsPage([ashaClassroom, balaClassroom], page: 1, totalPages: 2)),
      build: () => ClassroomBloc(classroom, options, 'i1'),
      act: (bloc) => bloc.add(const PagedListRequested()),
      expect: () => [
        const PagedListLoading<ClassroomEntry>(),
        const _Loaded([ashaEntry, balaEntry], hasMore: true),
      ],
    );

    blocTest<ClassroomBloc, PagedListState<ClassroomEntry>>(
      'passes the search on',
      setUp: () => when(
        () => classroom.students('i1', query: 'as'),
      ).thenAnswer((_) async => const ItemsPage([ashaClassroom], page: 1, totalPages: 1)),
      build: () => ClassroomBloc(classroom, options, 'i1'),
      act: (bloc) => bloc.add(const PagedListSearched('as')),
      expect: () => [
        const PagedListLoading<ClassroomEntry>(),
        const _Loaded([ashaEntry], query: 'as'),
      ],
    );

    blocTest<ClassroomBloc, PagedListState<ClassroomEntry>>(
      'says why the list could not be read',
      setUp: () => when(() => classroom.students('i1')).thenThrow(_notAssigned),
      build: () => ClassroomBloc(classroom, options, 'i1'),
      act: (bloc) => bloc.add(const PagedListRequested()),
      expect: () => [const PagedListLoading<ClassroomEntry>(), const PagedListFailed<ClassroomEntry>(_notAssigned)],
    );
  });

  group('ClassroomStudentBloc', () {
    blocTest<ClassroomStudentBloc, ClassroomStudentState>(
      'reads the student with the name of their section',
      setUp: () => when(() => classroom.student('p1')).thenAnswer((_) async => ashaClassroom),
      build: () => ClassroomStudentBloc(classroom, options, 'p1'),
      act: (bloc) => bloc.add(const ClassroomStudentRequested()),
      expect: () => [const ClassroomStudentLoading(), const ClassroomStudentLoaded(ashaEntry)],
    );

    blocTest<ClassroomStudentBloc, ClassroomStudentState>(
      'leaves the section unnamed when it is not among those offered',
      setUp: () => when(() => classroom.student('p2')).thenAnswer((_) async => balaClassroom),
      build: () => ClassroomStudentBloc(classroom, options, 'p2'),
      act: (bloc) => bloc.add(const ClassroomStudentRequested()),
      expect: () => [const ClassroomStudentLoading(), const ClassroomStudentLoaded(balaEntry)],
    );

    blocTest<ClassroomStudentBloc, ClassroomStudentState>(
      'says why it could not be read, and reads again on Try again',
      setUp: () => when(() => classroom.student('p1')).thenThrow(_notAssigned),
      build: () => ClassroomStudentBloc(classroom, options, 'p1'),
      act: (bloc) async {
        bloc.add(const ClassroomStudentRequested());
        await Future<void>.delayed(Duration.zero);
        when(() => classroom.student('p1')).thenAnswer((_) async => ashaClassroom);
        bloc.add(const ClassroomStudentRequested());
      },
      expect: () => [
        const ClassroomStudentLoading(),
        const ClassroomStudentFailed(_notAssigned),
        const ClassroomStudentLoading(),
        const ClassroomStudentLoaded(ashaEntry),
      ],
    );
  });
}
