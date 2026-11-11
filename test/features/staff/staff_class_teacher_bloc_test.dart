import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/section_options.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_class_teacher_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/classes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/sections.dart';
import '../../helpers/staff.dart';

void main() {
  late MockStaffRepository staff;
  late MockAcademicYearsRepository years;
  late MockClassesRepository classes;
  late MockSectionsRepository sections;

  // Kavya is based at i1, which has two years (the current one is y1), a class with two sections and a class with none.
  final leadsA = kavyaWith(
    classTeachers: [
      {'academicYearId': 'y1', 'sectionId': 'e1'},
    ],
  );
  const sectionChoices = [
    SectionChoice(id: 'e1', name: 'Class 1 · Section A'),
    SectionChoice(id: 'e2', name: 'Class 1 · Blue'),
  ];

  setUp(() {
    staff = MockStaffRepository();
    years = MockAcademicYearsRepository();
    classes = MockClassesRepository();
    sections = MockSectionsRepository();
    when(() => years.years('i1')).thenAnswer((_) async => [earlierYear, currentYear]);
    when(() => classes.classes('i1')).thenAnswer((_) async => [class1, pucClass]);
    when(() => sections.sections('k1')).thenAnswer((_) async => [sectionA, sectionB]);
  });

  StaffClassTeacherBloc build({StaffMember? member}) => StaffClassTeacherBloc(
    staff,
    SectionOptionsSource(years: years, classes: classes, sections: sections),
    member: member ?? leadsA,
  );

  Future<StaffClassTeacherBloc> opened({StaffMember? member}) async {
    final bloc = build(member: member);
    addTearDown(bloc.close);
    bloc.add(const StaffClassTeacherStarted());
    await bloc.stream.firstWhere((state) => state is StaffClassTeacherReady);
    return bloc;
  }

  StaffClassTeacherReady ready(StaffClassTeacherBloc bloc) => bloc.state as StaffClassTeacherReady;

  Future<void> waitFor(StaffClassTeacherBloc bloc, bool Function(StaffClassTeacherReady) test) =>
      bloc.stream.firstWhere((state) => state is StaffClassTeacherReady && test(state));

  group('starting', () {
    blocTest<StaffClassTeacherBloc, StaffClassTeacherState>(
      'reads the years and the sections of the home Institution, and shows the current year with its section',
      build: build,
      act: (bloc) => bloc.add(const StaffClassTeacherStarted()),
      expect: () => [
        const StaffClassTeacherLoading(),
        const StaffClassTeacherReady(
          years: [earlierYear, currentYear],
          sections: sectionChoices,
          assigned: {'y1': 'e1'},
          yearId: 'y1',
          sectionId: 'e1',
        ),
      ],
      verify: (_) => verifyNever(() => sections.sections('k9')),
    );

    blocTest<StaffClassTeacherBloc, StaffClassTeacherState>(
      'shows no section for a person who leads none',
      build: () => build(member: kavyaWith()),
      act: (bloc) => bloc.add(const StaffClassTeacherStarted()),
      verify: (bloc) {
        expect(ready(bloc).sectionId, isNull);
        expect(ready(bloc).assigned, isEmpty);
        expect(ready(bloc).changed, isFalse);
      },
    );

    blocTest<StaffClassTeacherBloc, StaffClassTeacherState>(
      'starts on the first year when none is current, and on none when there is no year',
      setUp: () => when(() => years.years('i1')).thenAnswer((_) async => [currentYearDemoted]),
      build: build,
      act: (bloc) => bloc.add(const StaffClassTeacherStarted()),
      verify: (bloc) => expect(ready(bloc).yearId, 'y1'),
    );

    blocTest<StaffClassTeacherBloc, StaffClassTeacherState>(
      'has no year to look at when the Institution has none',
      setUp: () => when(() => years.years('i1')).thenAnswer((_) async => []),
      build: build,
      act: (bloc) => bloc.add(const StaffClassTeacherStarted()),
      verify: (bloc) {
        expect(ready(bloc).yearId, isNull);
        expect(ready(bloc).changed, isFalse);
      },
    );

    blocTest<StaffClassTeacherBloc, StaffClassTeacherState>(
      'keeps the failure for the screen, and starts again on retry',
      setUp: () {
        var calls = 0;
        when(() => classes.classes('i1')).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [class1];
        });
      },
      build: build,
      act: (bloc) async {
        bloc.add(const StaffClassTeacherStarted());
        await bloc.stream.firstWhere((state) => state is StaffClassTeacherFailed);
        bloc.add(const StaffClassTeacherStarted());
      },
      expect: () => [
        const StaffClassTeacherLoading(),
        const StaffClassTeacherFailed(ApiFailure.network()),
        const StaffClassTeacherLoading(),
        isA<StaffClassTeacherReady>(),
      ],
    );

    blocTest<StaffClassTeacherBloc, StaffClassTeacherState>(
      'fails when the sections of a class cannot be read',
      setUp: () => when(() => sections.sections('k1')).thenThrow(const ApiFailure.network()),
      build: build,
      act: (bloc) => bloc.add(const StaffClassTeacherStarted()),
      expect: () => [const StaffClassTeacherLoading(), const StaffClassTeacherFailed(ApiFailure.network())],
    );
  });

  group('choosing', () {
    test('shows the section they lead in another year, and what was chosen for the first one is let go', () async {
      final bloc = await opened();
      bloc
        ..add(const StaffClassTeacherSectionChosen('e2'))
        ..add(const StaffClassTeacherYearChosen('y0'));
      await pumpEventQueue();
      expect(ready(bloc).yearId, 'y0');
      expect(ready(bloc).sectionId, isNull);
      expect(ready(bloc).changed, isFalse);
      bloc.add(const StaffClassTeacherYearChosen('y1'));
      await pumpEventQueue();
      expect(ready(bloc).sectionId, 'e1');
    });

    test('says what changed, and not when the section chosen is the one they lead', () async {
      final bloc = await opened();
      bloc.add(const StaffClassTeacherSectionChosen('e2'));
      await pumpEventQueue();
      expect(ready(bloc).changed, isTrue);
      bloc.add(const StaffClassTeacherSectionChosen('e1'));
      await pumpEventQueue();
      expect(ready(bloc).changed, isFalse);
      bloc.add(const StaffClassTeacherSectionChosen(null));
      await pumpEventQueue();
      expect(ready(bloc).changed, isTrue);
    });

    test('clears the last refusal once another year is chosen', () async {
      when(
        () => staff.setClassTeacher(
          any(),
          academicYearId: any(named: 'academicYearId'),
          sectionId: any(named: 'sectionId'),
        ),
      ).thenThrow(const ApiFailure(statusCode: 409, code: 'CLASS_TEACHER_TAKEN', message: 'x'));
      final bloc = await opened();
      bloc
        ..add(const StaffClassTeacherSectionChosen('e2'))
        ..add(const StaffClassTeacherSaved());
      await waitFor(bloc, (state) => state.failure != null);
      bloc.add(const StaffClassTeacherYearChosen('y0'));
      await pumpEventQueue();
      expect(ready(bloc).failure, isNull);
    });

    test('clears the last refusal once something is chosen', () async {
      when(
        () => staff.setClassTeacher(
          any(),
          academicYearId: any(named: 'academicYearId'),
          sectionId: any(named: 'sectionId'),
        ),
      ).thenThrow(const ApiFailure(statusCode: 409, code: 'CLASS_TEACHER_TAKEN', message: 'x'));
      final bloc = await opened();
      bloc
        ..add(const StaffClassTeacherSectionChosen('e2'))
        ..add(const StaffClassTeacherSaved());
      await waitFor(bloc, (state) => state.failure != null);
      bloc.add(const StaffClassTeacherSectionChosen('e1'));
      await pumpEventQueue();
      expect(ready(bloc).failure, isNull);
    });
  });

  group('saving', () {
    test('clears the last refusal when it is sent again, so a success leaves none', () async {
      var sent = 0;
      when(
        () => staff.setClassTeacher(
          any(),
          academicYearId: any(named: 'academicYearId'),
          sectionId: any(named: 'sectionId'),
        ),
      ).thenAnswer((_) async {
        if (sent++ == 0) throw const ApiFailure(statusCode: 409, code: 'CLASS_TEACHER_TAKEN', message: 'x');
        return const ClassTeacherAssignment(academicYearId: 'y1', sectionId: 'e2');
      });
      final bloc = await opened();
      bloc
        ..add(const StaffClassTeacherSectionChosen('e2'))
        ..add(const StaffClassTeacherSaved());
      await waitFor(bloc, (state) => state.failure != null);
      bloc.add(const StaffClassTeacherSaved());
      await waitFor(bloc, (state) => state.failure == null && !state.saving);
      expect(ready(bloc).assigned, {'y1': 'e2'});
    });

    test('sends the year and the section chosen, and takes the assignment the API answers with', () async {
      when(() => staff.setClassTeacher('f1', academicYearId: 'y1', sectionId: 'e2')).thenAnswer(
        (_) async => const ClassTeacherAssignment(academicYearId: 'y1', sectionId: 'e2'),
      );
      final bloc = await opened();
      bloc
        ..add(const StaffClassTeacherSectionChosen('e2'))
        ..add(const StaffClassTeacherSaved());
      await waitFor(bloc, (state) => !state.saving && state.assigned['y1'] == 'e2');
      expect(ready(bloc).changed, isFalse);
      expect(ready(bloc).failure, isNull);
    });

    test('takes what the API answers with as the section they lead, not what was chosen', () async {
      when(() => staff.setClassTeacher('f1', academicYearId: 'y1', sectionId: 'e2')).thenAnswer(
        (_) async => const ClassTeacherAssignment(academicYearId: 'y1', sectionId: 'e1'),
      );
      final bloc = await opened(member: kavyaWith());
      bloc
        ..add(const StaffClassTeacherSectionChosen('e2'))
        ..add(const StaffClassTeacherSaved());
      await waitFor(bloc, (state) => !state.saving && state.assigned['y1'] == 'e1');
      expect(ready(bloc).assigned, {'y1': 'e1'});
    });

    test('ends the duty for the year when no section is chosen, and then leads none in it', () async {
      when(() => staff.setClassTeacher('f1', academicYearId: 'y1')).thenAnswer((_) async => null);
      final bloc = await opened();
      bloc
        ..add(const StaffClassTeacherSectionChosen(null))
        ..add(const StaffClassTeacherSaved());
      await waitFor(bloc, (state) => !state.saving && state.assigned.isEmpty);
      expect(ready(bloc).sectionId, isNull);
      expect(ready(bloc).changed, isFalse);
    });

    test('keeps the other years as they are', () async {
      final both = kavyaWith(
        classTeachers: [
          {'academicYearId': 'y1', 'sectionId': 'e1'},
          {'academicYearId': 'y0', 'sectionId': 'e2'},
        ],
      );
      when(() => staff.setClassTeacher('f1', academicYearId: 'y1')).thenAnswer((_) async => null);
      final bloc = await opened(member: both);
      bloc
        ..add(const StaffClassTeacherSectionChosen(null))
        ..add(const StaffClassTeacherSaved());
      await waitFor(bloc, (state) => !state.saving && state.assigned.length == 1);
      expect(ready(bloc).assigned, {'y0': 'e2'});
    });

    test('sends nothing when nothing changed, or while a save is on its way', () async {
      final held = Completer<ClassTeacherAssignment?>();
      when(
        () => staff.setClassTeacher(
          any(),
          academicYearId: any(named: 'academicYearId'),
          sectionId: any(named: 'sectionId'),
        ),
      ).thenAnswer((_) => held.future);
      final bloc = await opened();
      bloc.add(const StaffClassTeacherSaved());
      await pumpEventQueue();
      verifyNever(
        () => staff.setClassTeacher(
          any(),
          academicYearId: any(named: 'academicYearId'),
          sectionId: any(named: 'sectionId'),
        ),
      );
      bloc
        ..add(const StaffClassTeacherSectionChosen('e2'))
        ..add(const StaffClassTeacherSaved());
      await waitFor(bloc, (state) => state.saving);
      bloc.add(const StaffClassTeacherSaved());
      await pumpEventQueue();
      verify(
        () => staff.setClassTeacher(
          any(),
          academicYearId: any(named: 'academicYearId'),
          sectionId: any(named: 'sectionId'),
        ),
      ).called(1);
      held.complete(const ClassTeacherAssignment(academicYearId: 'y1', sectionId: 'e2'));
    });

    test('leaves what is chosen as it is while it is on its way', () async {
      final held = Completer<ClassTeacherAssignment?>();
      when(
        () => staff.setClassTeacher(
          any(),
          academicYearId: any(named: 'academicYearId'),
          sectionId: any(named: 'sectionId'),
        ),
      ).thenAnswer((_) => held.future);
      final bloc = await opened();
      bloc
        ..add(const StaffClassTeacherSectionChosen('e2'))
        ..add(const StaffClassTeacherSaved());
      await waitFor(bloc, (state) => state.saving);
      bloc
        ..add(const StaffClassTeacherSectionChosen(null))
        ..add(const StaffClassTeacherYearChosen('y0'));
      await pumpEventQueue();
      expect(ready(bloc).yearId, 'y1');
      expect(ready(bloc).sectionId, 'e2');
      held.complete(const ClassTeacherAssignment(academicYearId: 'y1', sectionId: 'e2'));
    });

    for (final (status, code) in [
      (409, 'CLASS_TEACHER_TAKEN'),
      (422, 'STAFF_BLOCKED'),
      (422, 'REFERENCE_INACTIVE'),
      (404, 'NOT_FOUND'),
    ]) {
      test('keeps the choice, with the failure, when $code refuses it', () async {
        final failure = ApiFailure(statusCode: status, code: code, message: 'x');
        when(
          () => staff.setClassTeacher(
            any(),
            academicYearId: any(named: 'academicYearId'),
            sectionId: any(named: 'sectionId'),
          ),
        ).thenThrow(failure);
        final bloc = await opened();
        bloc
          ..add(const StaffClassTeacherSectionChosen('e2'))
          ..add(const StaffClassTeacherSaved());
        await waitFor(bloc, (state) => state.failure != null);
        expect(ready(bloc).failure, failure);
        expect(ready(bloc).sectionId, 'e2');
        expect(ready(bloc).saving, isFalse);
        expect(ready(bloc).assigned, {'y1': 'e1'});
        expect(ready(bloc).changed, isTrue);
      });
    }
  });
}
