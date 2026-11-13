import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_move_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/classes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/sections.dart';

const _down = ApiFailure(statusCode: 503, code: 'UNAVAILABLE', message: 'x');
const _taken = ApiFailure(statusCode: 409, code: 'ROLL_NUMBER_TAKEN', message: 'x');

/// Asha in Class 1 (k1), Section A (e1), roll 14.
const _asha = StudentSummary(
  id: 'p1',
  institutionId: 'i1',
  firstName: 'Asha',
  placement: StudentPlacement(
    academicYearId: 'y1',
    classId: 'k1',
    sectionId: 'e1',
    rollNumber: '14',
    startDate: '2026-06-01',
  ),
  isBlocked: false,
  version: 1,
);

/// Class 2 (k2), with one section.
const _class2 = SchoolClass(
  id: 'k2',
  institutionId: 'i1',
  predefinedClass: class2Ref,
  category: lowerPrimaryCategory,
  displayName: 'Class 2',
  sectionCount: 1,
  version: 1,
);
const _class2A = Section(
  id: 'e3',
  classId: 'k2',
  predefinedSection: sectionARef,
  displayName: 'Section A',
  version: 1,
);

void main() {
  late MockStudentsRepository students;
  late MockAcademicYearsRepository years;
  late MockClassesRepository classes;
  late MockSectionsRepository sections;

  setUp(() {
    students = MockStudentsRepository();
    years = MockAcademicYearsRepository();
    classes = MockClassesRepository();
    sections = MockSectionsRepository();
    when(() => years.years('i1')).thenAnswer((_) async => [currentYear]);
    when(() => classes.classes('i1')).thenAnswer((_) async => [class1, _class2, pucClass]);
    when(() => sections.sections('k1')).thenAnswer((_) async => [sectionA, sectionB]);
    when(() => sections.sections('k2')).thenAnswer((_) async => [_class2A]);
  });

  StudentMoveBloc build() => StudentMoveBloc(
    students,
    SectionOptionsSource(years: years, classes: classes, sections: sections),
    _asha,
  );

  Future<StudentMoveBloc> opened() async {
    final bloc = build()..add(const StudentMoveStarted());
    await bloc.stream.firstWhere((state) => state is StudentMoveReady);
    return bloc;
  }

  group('opening', () {
    blocTest<StudentMoveBloc, StudentMoveState>(
      'offers the classes that have sections, with the class and section the student is in chosen',
      build: build,
      act: (bloc) => bloc.add(const StudentMoveStarted()),
      expect: () => [
        const StudentMoveLoading(),
        isA<StudentMoveReady>()
            .having((s) => s.classes.map((c) => c.id), 'classes', ['k1', 'k2'])
            .having((s) => s.sectionsInClass.map((c) => c.id), 'sections of the class', ['e1', 'e2'])
            .having((s) => s.classId, 'class', 'k1')
            .having((s) => s.sectionId, 'section', 'e1')
            .having((s) => s.effectiveDate, 'day', isNull),
      ],
    );

    blocTest<StudentMoveBloc, StudentMoveState>(
      'fails when the sections cannot be read, and reads them again on Try again',
      setUp: () {
        var calls = 0;
        when(() => years.years('i1')).thenAnswer((_) async {
          if (calls++ == 0) throw _down;
          return [currentYear];
        });
      },
      build: build,
      act: (bloc) async {
        bloc.add(const StudentMoveStarted());
        await bloc.stream.firstWhere((state) => state is StudentMoveFailed);
        bloc.add(const StudentMoveStarted());
      },
      expect: () => [
        const StudentMoveLoading(),
        const StudentMoveFailed(_down),
        const StudentMoveLoading(),
        isA<StudentMoveReady>(),
      ],
    );

    test('ignores a choice made before it is ready', () async {
      final bloc = build()..add(const StudentMoveSectionChosen('e2'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, const StudentMoveLoading());
    });
  });

  group('choosing', () {
    test('keeps the section and the day, and ignores an emptied section', () async {
      final bloc = await opened();
      bloc
        ..add(const StudentMoveSectionChosen('e2'))
        ..add(const StudentMoveDateChosen('2026-07-01'))
        ..add(const StudentMoveSectionChosen(null));
      await Future<void>.delayed(Duration.zero);
      final state = bloc.state as StudentMoveReady;
      expect([state.sectionId, state.effectiveDate], ['e2', '2026-07-01']);
      bloc.add(const StudentMoveDateChosen(null));
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as StudentMoveReady).effectiveDate, isNull);
    });
  });

  group('choosing a class', () {
    test(
      'offers its sections and asks for one, and the day goes, because the class is corrected for the year',
      () async {
        final bloc = await opened();
        bloc
          ..add(const StudentMoveDateChosen('2026-07-01'))
          ..add(const StudentMoveClassChosen('k2'));
        await Future<void>.delayed(Duration.zero);
        final state = bloc.state as StudentMoveReady;
        expect([state.classId, state.sectionId, state.effectiveDate], ['k2', null, null]);
        expect(state.sectionsInClass.map((section) => section.id), ['e3']);
        bloc.add(const StudentMoveSectionChosen('e3'));
        await Future<void>.delayed(Duration.zero);
        expect((bloc.state as StudentMoveReady).sectionId, 'e3');
      },
    );

    test('goes back to the section the student is in when their own class is chosen again', () async {
      final bloc = await opened();
      bloc
        ..add(const StudentMoveClassChosen('k2'))
        ..add(const StudentMoveClassChosen('k1'));
      await Future<void>.delayed(Duration.zero);
      final state = bloc.state as StudentMoveReady;
      expect([state.classId, state.sectionId], ['k1', 'e1']);
    });

    test('ignores the class already chosen and an emptied class, and a choice while saving', () async {
      when(
        () => students.correctClass(
          any(),
          classId: any(named: 'classId'),
          sectionId: any(named: 'sectionId'),
          rollNumber: any(named: 'rollNumber'),
        ),
      ).thenAnswer((_) => Future<List<String>>.delayed(const Duration(milliseconds: 20), () => <String>[]));
      final bloc = await opened();
      bloc
        ..add(const StudentMoveClassChosen('k2'))
        ..add(const StudentMoveSectionChosen('e3'));
      await Future<void>.delayed(Duration.zero);
      final before = bloc.state;
      bloc
        ..add(const StudentMoveClassChosen('k2'))
        ..add(const StudentMoveClassChosen(null));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, before);
      bloc
        ..add(const StudentMoveSubmitted('14'))
        ..add(const StudentMoveClassChosen('k1'));
      await bloc.stream.firstWhere((state) => state is StudentMoveSaved);
      verify(() => students.correctClass('p1', classId: 'k2', sectionId: 'e3')).called(1);
    });
  });

  group('saving', () {
    test('sends only the section when only the section changed, and says the warnings', () async {
      when(
        () => students.move(
          any(),
          sectionId: any(named: 'sectionId'),
          rollNumber: any(named: 'rollNumber'),
          effectiveDate: any(named: 'effectiveDate'),
        ),
      ).thenAnswer((_) async => ['SECTION_OVER_CAPACITY']);
      final bloc = await opened();
      bloc
        ..add(const StudentMoveSectionChosen('e2'))
        ..add(const StudentMoveSubmitted(' 14 '));
      await bloc.stream.firstWhere((state) => state is StudentMoveSaved);
      expect(bloc.state, const StudentMoveSaved(['SECTION_OVER_CAPACITY']));
      verify(() => students.move('p1', sectionId: 'e2')).called(1);
    });

    test('sends only the roll number, trimmed, when only that changed, and the day when one is chosen', () async {
      when(
        () => students.move(
          any(),
          sectionId: any(named: 'sectionId'),
          rollNumber: any(named: 'rollNumber'),
          effectiveDate: any(named: 'effectiveDate'),
        ),
      ).thenAnswer((_) async => []);
      final bloc = await opened();
      bloc
        ..add(const StudentMoveDateChosen('2026-07-01'))
        ..add(const StudentMoveSubmitted(' 15 '));
      await bloc.stream.firstWhere((state) => state is StudentMoveSaved);
      verify(() => students.move('p1', rollNumber: '15', effectiveDate: '2026-07-01')).called(1);
    });

    test('stays on the form with the refusal, and sends again once something is changed', () async {
      when(
        () => students.move(
          any(),
          sectionId: any(named: 'sectionId'),
          rollNumber: any(named: 'rollNumber'),
          effectiveDate: any(named: 'effectiveDate'),
        ),
      ).thenThrow(_taken);
      final bloc = await opened();
      bloc.add(const StudentMoveSubmitted('15'));
      await bloc.stream.firstWhere((state) => state is StudentMoveReady && state.failure != null);
      var state = bloc.state as StudentMoveReady;
      expect([state.saving, state.failure], [false, _taken]);
      bloc.add(const StudentMoveDateChosen('2026-07-01'));
      await Future<void>.delayed(Duration.zero);
      state = bloc.state as StudentMoveReady;
      expect(state.failure, isNull);
    });

    test('does not send twice while saving, and changes nothing meanwhile', () async {
      final released = Future<List<String>>.delayed(const Duration(milliseconds: 20), () => <String>[]);
      when(
        () => students.move(
          any(),
          sectionId: any(named: 'sectionId'),
          rollNumber: any(named: 'rollNumber'),
          effectiveDate: any(named: 'effectiveDate'),
        ),
      ).thenAnswer((_) => released);
      final bloc = await opened();
      bloc
        ..add(const StudentMoveSubmitted('15'))
        ..add(const StudentMoveSubmitted('16'))
        ..add(const StudentMoveSectionChosen('e2'))
        ..add(const StudentMoveDateChosen('2026-07-01'));
      await bloc.stream.firstWhere((state) => state is StudentMoveSaved);
      verify(() => students.move('p1', rollNumber: '15')).called(1);
      verifyNoMoreInteractions(students);
    });

    test('corrects the class, with the roll number only when it changed, and says the warnings', () async {
      when(
        () => students.correctClass(
          any(),
          classId: any(named: 'classId'),
          sectionId: any(named: 'sectionId'),
          rollNumber: any(named: 'rollNumber'),
        ),
      ).thenAnswer((_) async => ['SECTION_OVER_CAPACITY']);
      final bloc = await opened();
      bloc
        ..add(const StudentMoveClassChosen('k2'))
        ..add(const StudentMoveSectionChosen('e3'))
        ..add(const StudentMoveSubmitted(' 3 '));
      await bloc.stream.firstWhere((state) => state is StudentMoveSaved);
      expect(bloc.state, const StudentMoveSaved(['SECTION_OVER_CAPACITY']));
      verify(() => students.correctClass('p1', classId: 'k2', sectionId: 'e3', rollNumber: '3')).called(1);
      verifyNever(
        () => students.move(
          any(),
          sectionId: any(named: 'sectionId'),
          rollNumber: any(named: 'rollNumber'),
          effectiveDate: any(named: 'effectiveDate'),
        ),
      );
    });

    test('sends nothing for another class until a section of it is chosen', () async {
      final bloc = await opened();
      bloc
        ..add(const StudentMoveClassChosen('k2'))
        ..add(const StudentMoveSubmitted('14'));
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as StudentMoveReady).saving, isFalse);
      verifyZeroInteractions(students);
    });

    test('stays on the form with the refusal of the class, and shows it until something is chosen', () async {
      const below = ApiFailure(statusCode: 422, code: 'TARGET_CLASS_BELOW_SOURCE', message: 'x');
      when(
        () => students.correctClass(
          any(),
          classId: any(named: 'classId'),
          sectionId: any(named: 'sectionId'),
          rollNumber: any(named: 'rollNumber'),
        ),
      ).thenThrow(below);
      final bloc = await opened();
      bloc
        ..add(const StudentMoveClassChosen('k2'))
        ..add(const StudentMoveSectionChosen('e3'))
        ..add(const StudentMoveSubmitted('14'));
      await bloc.stream.firstWhere((state) => state is StudentMoveReady && state.failure != null);
      expect((bloc.state as StudentMoveReady).failure, below);
      bloc.add(const StudentMoveClassChosen('k1'));
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as StudentMoveReady).failure, isNull);
    });
  });
}
