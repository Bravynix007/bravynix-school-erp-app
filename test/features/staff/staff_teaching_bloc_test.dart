import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/section_options.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_teaching_bloc.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/domain/teaching_assignment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/classes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/sections.dart';
import '../../helpers/staff.dart';
import '../../helpers/subjects.dart';
import '../../helpers/teaching_assignments.dart';

void main() {
  late MockTeachingAssignmentsRepository assignments;
  late MockAcademicYearsRepository years;
  late MockClassesRepository classes;
  late MockSectionsRepository sections;
  late MockSubjectsRepository subjects;

  // Kavya is based at i1, which has two years (the current one is y1), a class with two sections and a class with none.
  // Her list holds Mathematics only; Art is a subject of the Society she does not teach.
  const sectionChoices = [
    SectionChoice(id: 'e1', name: 'Class 1 · Section A'),
    SectionChoice(id: 'e2', name: 'Class 1 · Blue'),
  ];
  const failure = ApiFailure(statusCode: 409, code: 'DUPLICATE', message: 'x');

  ItemsPage<TeachingAssignment> only(List<TeachingAssignment> items) => ItemsPage(items, page: 1, totalPages: 1);

  void reads(String yearId, List<TeachingAssignment> items) {
    when(
      () => assignments.assignments(
        'i1',
        academicYearId: yearId,
        staffMemberId: 'f1',
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => only(items));
  }

  void makes(TeachingAssignment made) {
    when(
      () => assignments.assign(
        staffMemberId: 'f1',
        academicYearId: made.academicYearId,
        sectionId: made.sectionId,
        subjectId: made.subjectId,
      ),
    ).thenAnswer((_) async => made);
  }

  setUp(() {
    assignments = MockTeachingAssignmentsRepository();
    years = MockAcademicYearsRepository();
    classes = MockClassesRepository();
    sections = MockSectionsRepository();
    subjects = MockSubjectsRepository();
    when(() => years.years('i1')).thenAnswer((_) async => [earlierYear, currentYear]);
    when(() => classes.classes('i1')).thenAnswer((_) async => [class1, pucClass]);
    when(() => sections.sections('k1')).thenAnswer((_) async => [sectionA, sectionB]);
    when(subjects.subjects).thenAnswer((_) async => [art, maths]);
    reads('y1', [mathsInClass1A]);
    reads('y0', []);
  });

  StaffTeachingBloc build({StaffMember? member}) => StaffTeachingBloc(
    assignments,
    SectionOptionsSource(years: years, classes: classes, sections: sections),
    subjects,
    member: member ?? kavyaMember,
  );

  Future<StaffTeachingBloc> opened({StaffMember? member}) async {
    final bloc = build(member: member);
    addTearDown(bloc.close);
    bloc.add(const StaffTeachingStarted());
    await bloc.stream.firstWhere((state) => state is StaffTeachingReady);
    return bloc;
  }

  StaffTeachingReady ready(StaffTeachingBloc bloc) => bloc.state as StaffTeachingReady;

  Future<void> waitFor(StaffTeachingBloc bloc, bool Function(StaffTeachingReady) test) =>
      bloc.stream.firstWhere((state) => state is StaffTeachingReady && test(state));

  group('starting', () {
    blocTest<StaffTeachingBloc, StaffTeachingState>(
      'reads the years, the sections, the subjects on their own list and what they teach in the current year',
      build: build,
      act: (bloc) => bloc.add(const StaffTeachingStarted()),
      expect: () => [
        const StaffTeachingLoading(),
        const StaffTeachingReady(
          years: [earlierYear, currentYear],
          sections: sectionChoices,
          subjects: [maths],
          yearId: 'y1',
          assignments: [mathsInClass1A],
        ),
      ],
    );

    blocTest<StaffTeachingBloc, StaffTeachingState>(
      'reads nothing of what they teach when the Institution has no academic year',
      setUp: () => when(() => years.years('i1')).thenAnswer((_) async => []),
      build: build,
      act: (bloc) => bloc.add(const StaffTeachingStarted()),
      expect: () => [
        const StaffTeachingLoading(),
        const StaffTeachingReady(years: [], sections: sectionChoices, subjects: [maths], yearId: null, assignments: []),
      ],
      verify: (_) => verifyNever(
        () => assignments.assignments(
          any(),
          academicYearId: any(named: 'academicYearId'),
          staffMemberId: any(named: 'staffMemberId'),
          page: any(named: 'page'),
        ),
      ),
    );

    test('reads every page of what they teach', () async {
      when(() => assignments.assignments('i1', academicYearId: 'y1', staffMemberId: 'f1')).thenAnswer(
        (_) async => const ItemsPage([mathsInClass1A], page: 1, totalPages: 2),
      );
      when(() => assignments.assignments('i1', academicYearId: 'y1', staffMemberId: 'f1', page: 2)).thenAnswer(
        (_) async => const ItemsPage([mathsInClass1Blue], page: 2, totalPages: 2),
      );
      final bloc = await opened();
      expect(ready(bloc).assignments, [mathsInClass1A, mathsInClass1Blue]);
    });

    test('offers the subjects of their list only, and none when the list is empty', () async {
      final bloc = await opened(member: kavyaWith());
      expect(ready(bloc).subjects, isEmpty);
    });

    blocTest<StaffTeachingBloc, StaffTeachingState>(
      'fails with the refusal when something cannot be read, and reads again on Try again',
      setUp: () => when(() => sections.sections('k1')).thenThrow(const ApiFailure.network()),
      build: build,
      act: (bloc) => bloc.add(const StaffTeachingStarted()),
      expect: () => [const StaffTeachingLoading(), const StaffTeachingFailed(ApiFailure.network())],
    );

    test('fails when what they teach cannot be read', () async {
      when(
        () => assignments.assignments(
          'i1',
          academicYearId: 'y1',
          staffMemberId: 'f1',
          page: any(named: 'page'),
        ),
      ).thenThrow(const ApiFailure.network());
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const StaffTeachingStarted());
      await bloc.stream.firstWhere((state) => state is StaffTeachingFailed);
      reads('y1', [mathsInClass1A]);
      bloc.add(const StaffTeachingStarted());
      await bloc.stream.firstWhere((state) => state is StaffTeachingReady);
      expect(ready(bloc).assignments, [mathsInClass1A]);
    });
  });

  group('choosing a year', () {
    test('reads what they teach in it, and shows a wait while it does', () async {
      final held = Completer<ItemsPage<TeachingAssignment>>();
      final bloc = await opened();
      when(
        () => assignments.assignments(
          'i1',
          academicYearId: 'y0',
          staffMemberId: 'f1',
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) => held.future);
      bloc.add(const StaffTeachingYearChosen('y0'));
      await waitFor(bloc, (state) => state.reading);
      expect(ready(bloc).yearId, 'y0');
      expect(ready(bloc).assignments, isEmpty);
      expect(ready(bloc).busy, isTrue);
      held.complete(only([mathsInClass1Blue]));
      await waitFor(bloc, (state) => !state.reading);
      expect(ready(bloc).assignments, [mathsInClass1Blue]);
    });

    test('clears the last refusal and the last change', () async {
      makes(mathsInClass1Blue);
      final bloc = await opened();
      bloc
        ..add(const StaffTeachingSectionChosen('e2'))
        ..add(const StaffTeachingSubjectChosen('u1'))
        ..add(const StaffTeachingAdded());
      await waitFor(bloc, (state) => state.done != null);
      bloc.add(const StaffTeachingYearChosen('y0'));
      await waitFor(bloc, (state) => !state.reading && state.yearId == 'y0');
      expect(ready(bloc).done, isNull);
    });

    test('does nothing for the year already shown', () async {
      final bloc = await opened();
      bloc.add(const StaffTeachingYearChosen('y1'));
      await pumpEventQueue();
      expect(ready(bloc).reading, isFalse);
      verify(
        () => assignments.assignments(
          'i1',
          academicYearId: 'y1',
          staffMemberId: 'f1',
          page: any(named: 'page'),
        ),
      ).called(1);
    });

    test('fails when what they teach in it cannot be read', () async {
      final bloc = await opened();
      when(
        () => assignments.assignments(
          'i1',
          academicYearId: 'y0',
          staffMemberId: 'f1',
          page: any(named: 'page'),
        ),
      ).thenThrow(const ApiFailure.network());
      bloc.add(const StaffTeachingYearChosen('y0'));
      await bloc.stream.firstWhere((state) => state is StaffTeachingFailed);
    });
  });

  group('once their subjects are saved', () {
    test('offers the subjects now on their list, without reading again', () async {
      final bloc = await opened();
      bloc.add(const StaffTeachingSubjectsChanged(['u1', 'u2']));
      await pumpEventQueue();
      expect(ready(bloc).subjects, [art, maths]);
      expect(ready(bloc).assignments, [mathsInClass1A]);
      verify(subjects.subjects).called(1);
      verify(
        () => assignments.assignments(
          'i1',
          academicYearId: 'y1',
          staffMemberId: 'f1',
          page: any(named: 'page'),
        ),
      ).called(1);
    });

    test('keeps the subject being chosen while it is still offered, and drops it when it is not', () async {
      final bloc = await opened();
      bloc
        ..add(const StaffTeachingSubjectChosen('u1'))
        ..add(const StaffTeachingSubjectsChanged(['u1', 'u2']));
      await pumpEventQueue();
      expect(ready(bloc).subjectId, 'u1');
      bloc.add(const StaffTeachingSubjectsChanged(['u2']));
      await pumpEventQueue();
      expect(ready(bloc).subjects, [art]);
      expect(ready(bloc).subjectId, isNull);
    });

    test('leaves an assignment on its way alone', () async {
      final held = Completer<TeachingAssignment>();
      when(
        () => assignments.assign(staffMemberId: 'f1', academicYearId: 'y1', sectionId: 'e2', subjectId: 'u1'),
      ).thenAnswer((_) => held.future);
      final bloc = await opened();
      bloc
        ..add(const StaffTeachingSectionChosen('e2'))
        ..add(const StaffTeachingSubjectChosen('u1'))
        ..add(const StaffTeachingAdded());
      await waitFor(bloc, (state) => state.adding);
      bloc.add(const StaffTeachingSubjectsChanged(['u1', 'u2']));
      await pumpEventQueue();
      expect(ready(bloc).adding, isTrue);
      held.complete(mathsInClass1Blue);
      await waitFor(bloc, (state) => !state.adding);
      expect(ready(bloc).assignments, [mathsInClass1A, mathsInClass1Blue]);
    });

    test('is not heard before the section is ready, and the subjects are then those of the staff member', () async {
      final bloc = build()..add(const StaffTeachingSubjectsChanged(['u1', 'u2']));
      addTearDown(bloc.close);
      await pumpEventQueue();
      expect(bloc.state, const StaffTeachingLoading());
    });
  });

  group('choosing', () {
    test('lets Assign be pressed only once a section and a subject are chosen', () async {
      final bloc = await opened();
      expect(ready(bloc).canAdd, isFalse);
      bloc.add(const StaffTeachingSectionChosen('e2'));
      await pumpEventQueue();
      expect(ready(bloc).canAdd, isFalse);
      bloc.add(const StaffTeachingSubjectChosen('u1'));
      await pumpEventQueue();
      expect(ready(bloc).canAdd, isTrue);
      bloc.add(const StaffTeachingSectionChosen(null));
      await pumpEventQueue();
      expect(ready(bloc).canAdd, isFalse);
    });

    test('clears the last refusal once something is chosen', () async {
      when(
        () => assignments.assign(
          staffMemberId: any(named: 'staffMemberId'),
          academicYearId: any(named: 'academicYearId'),
          sectionId: any(named: 'sectionId'),
          subjectId: any(named: 'subjectId'),
        ),
      ).thenThrow(failure);
      final bloc = await opened();
      bloc
        ..add(const StaffTeachingSectionChosen('e1'))
        ..add(const StaffTeachingSubjectChosen('u1'))
        ..add(const StaffTeachingAdded());
      await waitFor(bloc, (state) => state.failure != null);
      bloc.add(const StaffTeachingSubjectChosen(null));
      await pumpEventQueue();
      expect(ready(bloc).failure, isNull);
    });
  });

  group('assigning', () {
    test('sends the year, the section and the subject, adds what the API answers with and clears the choice', () async {
      makes(mathsInClass1Blue);
      final bloc = await opened();
      bloc
        ..add(const StaffTeachingSectionChosen('e2'))
        ..add(const StaffTeachingSubjectChosen('u1'))
        ..add(const StaffTeachingAdded());
      await waitFor(bloc, (state) => state.done != null);
      expect(ready(bloc).assignments, [mathsInClass1A, mathsInClass1Blue]);
      expect(ready(bloc).done, const StaffTeachingChange(mathsInClass1Blue, ended: false));
      expect(ready(bloc).sectionId, isNull);
      expect(ready(bloc).subjectId, isNull);
      expect(ready(bloc).adding, isFalse);
      expect(ready(bloc).failure, isNull);
    });

    test('keeps the choice and says why when it is refused', () async {
      when(
        () => assignments.assign(staffMemberId: 'f1', academicYearId: 'y1', sectionId: 'e1', subjectId: 'u1'),
      ).thenThrow(failure);
      final bloc = await opened();
      bloc
        ..add(const StaffTeachingSectionChosen('e1'))
        ..add(const StaffTeachingSubjectChosen('u1'))
        ..add(const StaffTeachingAdded());
      await waitFor(bloc, (state) => state.failure != null);
      expect(ready(bloc).failure, failure);
      expect(ready(bloc).sectionId, 'e1');
      expect(ready(bloc).subjectId, 'u1');
      expect(ready(bloc).adding, isFalse);
      expect(ready(bloc).assignments, [mathsInClass1A]);
    });

    test('sends nothing when the choice is not complete, or while another is on its way', () async {
      final held = Completer<TeachingAssignment>();
      when(
        () => assignments.assign(staffMemberId: 'f1', academicYearId: 'y1', sectionId: 'e2', subjectId: 'u1'),
      ).thenAnswer((_) => held.future);
      final bloc = await opened();
      bloc.add(const StaffTeachingAdded());
      await pumpEventQueue();
      verifyNever(
        () => assignments.assign(
          staffMemberId: any(named: 'staffMemberId'),
          academicYearId: any(named: 'academicYearId'),
          sectionId: any(named: 'sectionId'),
          subjectId: any(named: 'subjectId'),
        ),
      );
      bloc
        ..add(const StaffTeachingSectionChosen('e2'))
        ..add(const StaffTeachingSubjectChosen('u1'))
        ..add(const StaffTeachingAdded());
      await waitFor(bloc, (state) => state.adding);
      bloc
        ..add(const StaffTeachingAdded())
        ..add(const StaffTeachingYearChosen('y0'));
      await pumpEventQueue();
      expect(ready(bloc).yearId, 'y1');
      held.complete(mathsInClass1Blue);
      await waitFor(bloc, (state) => !state.adding);
      verify(
        () => assignments.assign(staffMemberId: 'f1', academicYearId: 'y1', sectionId: 'e2', subjectId: 'u1'),
      ).called(1);
    });
  });

  group('ending', () {
    test('ends the assignment and takes it off the list, saying which', () async {
      when(() => assignments.end('g1')).thenAnswer((_) async {});
      final bloc = await opened();
      bloc.add(const StaffTeachingEnded('g1'));
      await waitFor(bloc, (state) => state.done != null);
      expect(ready(bloc).assignments, isEmpty);
      expect(ready(bloc).done, const StaffTeachingChange(mathsInClass1A, ended: true));
      expect(ready(bloc).ending, isNull);
    });

    test('keeps the assignment and says why when it is refused', () async {
      when(() => assignments.end('g1')).thenThrow(const ApiFailure.network());
      final bloc = await opened();
      bloc.add(const StaffTeachingEnded('g1'));
      await waitFor(bloc, (state) => state.failure != null);
      expect(ready(bloc).assignments, [mathsInClass1A]);
      expect(ready(bloc).ending, isNull);
    });

    test('takes the assignment off the list when the API says it is not there, and says so', () async {
      when(() => assignments.end('g1')).thenThrow(const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x'));
      final bloc = await opened();
      bloc.add(const StaffTeachingEnded('g1'));
      await waitFor(bloc, (state) => state.failure != null);
      expect(ready(bloc).assignments, isEmpty);
      expect(ready(bloc).done, isNull);
    });

    test('shows which one is on its way, and does nothing for one that is not on the list or while busy', () async {
      final held = Completer<void>();
      when(() => assignments.end('g1')).thenAnswer((_) => held.future);
      final bloc = await opened();
      bloc.add(const StaffTeachingEnded('g9'));
      await pumpEventQueue();
      expect(ready(bloc).ending, isNull);
      bloc.add(const StaffTeachingEnded('g1'));
      await waitFor(bloc, (state) => state.ending == 'g1');
      bloc.add(const StaffTeachingEnded('g1'));
      await pumpEventQueue();
      held.complete();
      await waitFor(bloc, (state) => state.ending == null);
      verify(() => assignments.end('g1')).called(1);
    });
  });
}
