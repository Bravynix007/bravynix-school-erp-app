import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
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
    when(() => classes.classes('i1')).thenAnswer((_) async => [class1, pucClass]);
    when(() => sections.sections('k1')).thenAnswer((_) async => [sectionA, sectionB]);
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
      'offers the sections of the class the student is in, with the one they are in chosen',
      build: build,
      act: (bloc) => bloc.add(const StudentMoveStarted()),
      expect: () => [
        const StudentMoveLoading(),
        isA<StudentMoveReady>()
            .having((s) => s.sections.map((c) => c.id), 'sections', ['e1', 'e2'])
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
  });
}
