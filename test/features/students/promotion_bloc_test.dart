import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/promotion.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/promotion_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/classes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/sections.dart';
import '../../helpers/students.dart';

const _down = ApiFailure(statusCode: 503, code: 'UNAVAILABLE', message: 'x');
const _below = ApiFailure(statusCode: 422, code: 'TARGET_CLASS_BELOW_SOURCE', message: 'x');

/// The year after the current one.
const _nextYear = AcademicYear(
  id: 'y2',
  institutionId: 'i1',
  name: '2027-2028',
  startDate: '2027-06-01',
  endDate: '2028-03-31',
  isCurrent: false,
  version: 1,
);

/// Asha in Class 1 (k1), Section A (e1), roll 14, in the current year (y1).
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

const _target = PromotionTarget(academicYearId: 'y2', classId: 'k2', sectionId: 'e3');

void main() {
  late MockStudentsRepository students;
  late MockAcademicYearsRepository years;
  late MockClassesRepository classes;
  late MockSectionsRepository sections;
  late int keys;

  setUp(() {
    students = MockStudentsRepository();
    years = MockAcademicYearsRepository();
    classes = MockClassesRepository();
    sections = MockSectionsRepository();
    keys = 0;
    when(() => years.years('i1')).thenAnswer((_) async => [_nextYear, currentYear, earlierYear]);
    when(() => classes.classes('i1')).thenAnswer((_) async => [class1, _class2, pucClass]);
    when(() => sections.sections('k1')).thenAnswer((_) async => [sectionA, sectionB]);
    when(() => sections.sections('k2')).thenAnswer((_) async => [_class2A]);
  });

  PromotionBloc build(PromotionScope scope) => PromotionBloc(
    students,
    SectionOptionsSource(years: years, classes: classes, sections: sections),
    scope,
    newKey: () => 'key-${++keys}',
  );

  Future<PromotionBloc> opened(PromotionScope scope) async {
    final bloc = build(scope)..add(const PromotionStarted());
    await bloc.stream.firstWhere((state) => state is PromotionReady);
    return bloc;
  }

  PromotionReady ready(PromotionBloc bloc) => bloc.state as PromotionReady;

  group('opening for one student', () {
    blocTest<PromotionBloc, PromotionState>(
      'keeps where they sit, and aims at the year after theirs and the class after theirs, with no section yet',
      build: () => build(const PromoteOne(_asha)),
      act: (bloc) => bloc.add(const PromotionStarted()),
      expect: () => [
        const PromotionLoading(),
        isA<PromotionReady>()
            .having((s) => [s.sourceYearId, s.sourceClassId, s.sourceSectionId], 'source', ['y1', 'k1', 'e1'])
            .having((s) => s.targetYears.map((y) => y.id), 'years to go to', ['y2'])
            .having((s) => [s.targetYearId, s.targetClassId, s.targetSectionId], 'target', ['y2', 'k2', null])
            .having((s) => s.canSubmit, 'can submit', isFalse),
      ],
    );

    blocTest<PromotionBloc, PromotionState>(
      'stays in the last class it can, when theirs is the last with sections',
      setUp: () => when(() => classes.classes('i1')).thenAnswer((_) async => [class1, _class2]),
      build: () => build(
        const PromoteOne(
          StudentSummary(
            id: 'p1',
            institutionId: 'i1',
            firstName: 'Asha',
            placement: StudentPlacement(
              academicYearId: 'y1',
              classId: 'k2',
              sectionId: 'e3',
              rollNumber: '14',
              startDate: '2026-06-01',
            ),
            isBlocked: false,
            version: 1,
          ),
        ),
      ),
      act: (bloc) => bloc.add(const PromotionStarted()),
      expect: () => [
        const PromotionLoading(),
        isA<PromotionReady>().having((s) => s.targetClassId, 'target class', 'k2'),
      ],
    );

    blocTest<PromotionBloc, PromotionState>(
      'fails when the choices cannot be read, and reads them again on Try again',
      setUp: () {
        var calls = 0;
        when(() => years.years('i1')).thenAnswer((_) async {
          if (calls++ == 0) throw _down;
          return [_nextYear, currentYear];
        });
      },
      build: () => build(const PromoteOne(_asha)),
      act: (bloc) async {
        bloc.add(const PromotionStarted());
        await bloc.stream.firstWhere((state) => state is PromotionFailed);
        bloc.add(const PromotionStarted());
      },
      expect: () => [
        const PromotionLoading(),
        const PromotionFailed(_down),
        const PromotionLoading(),
        isA<PromotionReady>(),
      ],
    );
  });

  group('choosing where one student goes', () {
    test('a class resets the section, and a section makes it possible to promote', () async {
      final bloc = await opened(const PromoteOne(_asha));
      bloc.add(const PromotionTargetSectionChosen('e3'));
      await bloc.stream.firstWhere((state) => state is PromotionReady && state.targetSectionId == 'e3');
      expect(ready(bloc).canSubmit, isTrue);
      expect(ready(bloc).target, _target);
      expect(ready(bloc).targetName, 'Class 2 · Section A');
      bloc.add(const PromotionTargetClassChosen('k1'));
      await bloc.stream.firstWhere((state) => state is PromotionReady && state.targetClassId == 'k1');
      expect(ready(bloc).targetSectionId, isNull);
      expect(ready(bloc).targetSections.map((s) => s.id), ['e1', 'e2']);
      expect(ready(bloc).canSubmit, isFalse);
      await bloc.close();
    });

    test('completing the final class needs no target, and a choice of none is ignored', () async {
      final bloc = await opened(const PromoteOne(_asha));
      bloc
        ..add(const PromotionTargetYearChosen(null))
        ..add(const PromotionCompletesToggled(value: true));
      await bloc.stream.firstWhere((state) => state is PromotionReady && state.completes);
      expect(ready(bloc).targetYearId, 'y2');
      expect(ready(bloc).target, isNull);
      expect(ready(bloc).canSubmit, isTrue);
      await bloc.close();
    });
  });

  group('promoting one student', () {
    blocTest<PromotionBloc, PromotionState>(
      'sends the target, keeps their roll number when it is left as it is, and says where they went',
      setUp: () => when(
        () => students.promoteStudent('p1', target: _target),
      ).thenAnswer((_) async => const Promoted(ashaRecord, warnings: ['SECTION_OVER_CAPACITY'])),
      build: () => build(const PromoteOne(_asha)),
      act: (bloc) async {
        bloc.add(const PromotionStarted());
        await bloc.stream.firstWhere((state) => state is PromotionReady);
        bloc
          ..add(const PromotionTargetSectionChosen('e3'))
          ..add(const PromotionSubmitted(rollNumber: ' 14 '));
      },
      skip: 2,
      expect: () => [
        isA<PromotionReady>().having((s) => s.targetSectionId, 'section', 'e3'),
        isA<PromotionReady>().having((s) => s.saving, 'saving', isTrue),
        const PromotionDone(
          PromotionResult(promotedCount: 1, warnings: ['SECTION_OVER_CAPACITY']),
          targetName: 'Class 2 · Section A',
        ),
      ],
    );

    test('sends another roll number when one is typed', () async {
      when(
        () => students.promoteStudent('p1', target: _target, rollNumber: '20'),
      ).thenAnswer((_) async => const Promoted(ashaRecord));
      final bloc = await opened(const PromoteOne(_asha));
      bloc
        ..add(const PromotionTargetSectionChosen('e3'))
        ..add(const PromotionSubmitted(rollNumber: '20'));
      await bloc.stream.firstWhere((state) => state is PromotionDone);
      verify(() => students.promoteStudent('p1', target: _target, rollNumber: '20')).called(1);
      await bloc.close();
    });

    test('sends no target to complete the final class even after one was chosen, and says so', () async {
      when(() => students.promoteStudent('p1')).thenAnswer((_) async => const Promoted(ashaRecord));
      final bloc = await opened(const PromoteOne(_asha));
      // A target chosen, and a roll number typed, before the final class was chosen are not sent: they belong to a new place.
      bloc
        ..add(const PromotionTargetSectionChosen('e3'))
        ..add(const PromotionCompletesToggled(value: true))
        ..add(const PromotionSubmitted(rollNumber: '20'));
      final done = await bloc.stream.firstWhere((state) => state is PromotionDone) as PromotionDone;
      expect(done.targetName, isNull);
      verify(() => students.promoteStudent('p1')).called(1);
      await bloc.close();
    });

    test('sends nothing before a section is chosen', () async {
      final bloc = await opened(const PromoteOne(_asha));
      bloc.add(const PromotionSubmitted());
      await Future<void>.delayed(Duration.zero);
      verifyNever(
        () => students.promoteStudent(
          any(),
          target: any(named: 'target'),
          rollNumber: any(named: 'rollNumber'),
        ),
      );
      await bloc.close();
    });

    test('says why it was refused, keeps the choices, and forgets the refusal at the next choice', () async {
      when(
        () => students.promoteStudent(
          any(),
          target: any(named: 'target'),
          rollNumber: any(named: 'rollNumber'),
        ),
      ).thenThrow(_below);
      final bloc = await opened(const PromoteOne(_asha));
      bloc
        ..add(const PromotionTargetSectionChosen('e3'))
        ..add(const PromotionSubmitted());
      await bloc.stream.firstWhere((state) => state is PromotionReady && state.failure != null);
      expect(ready(bloc).saving, isFalse);
      expect(ready(bloc).targetSectionId, 'e3');
      bloc.add(const PromotionTargetYearChosen('y2'));
      await bloc.stream.firstWhere((state) => state is PromotionReady && state.failure == null);
      await bloc.close();
    });
  });

  group('opening for a class', () {
    blocTest<PromotionBloc, PromotionState>(
      'offers the current year and the first class, every section of it, and aims at the next year and class',
      build: () => build(const PromoteGroup('i1')),
      act: (bloc) => bloc.add(const PromotionStarted()),
      expect: () => [
        const PromotionLoading(),
        isA<PromotionReady>()
            .having((s) => [s.sourceYearId, s.sourceClassId, s.sourceSectionId], 'source', ['y1', 'k1', null])
            .having((s) => s.sourceSections.map((c) => c.id), 'sections to choose', ['e1', 'e2'])
            .having((s) => [s.targetYearId, s.targetClassId, s.targetSectionId], 'target', ['y2', 'k2', null])
            .having((s) => s.keepRollNumbers, 'keeps roll numbers', isTrue),
      ],
    );

    test(
      'another source class forgets its section and aims again, and another year aims at the one after it',
      () async {
        final bloc = await opened(const PromoteGroup('i1'));
        bloc.add(const PromotionSourceSectionChosen('e2'));
        await bloc.stream.firstWhere((state) => state is PromotionReady && state.sourceSectionId == 'e2');
        bloc.add(const PromotionSourceClassChosen('k2'));
        await bloc.stream.firstWhere((state) => state is PromotionReady && state.sourceClassId == 'k2');
        expect(ready(bloc).sourceSectionId, isNull);
        // The last class with sections stays where it is.
        expect(ready(bloc).targetClassId, 'k2');
        bloc.add(const PromotionSourceYearChosen('y0'));
        await bloc.stream.firstWhere((state) => state is PromotionReady && state.sourceYearId == 'y0');
        expect(ready(bloc).targetYearId, 'y1');
        expect(ready(bloc).targetYears.map((y) => y.id), ['y1', 'y2']);
        await bloc.close();
      },
    );

    test('every section again is a choice of none', () async {
      final bloc = await opened(const PromoteGroup('i1'));
      bloc.add(const PromotionSourceSectionChosen('e2'));
      await bloc.stream.firstWhere((state) => state is PromotionReady && state.sourceSectionId == 'e2');
      bloc.add(const PromotionSourceSectionChosen(null));
      await bloc.stream.firstWhere((state) => state is PromotionReady && state.sourceSectionId == null);
      await bloc.close();
    });
  });

  group('promoting a class', () {
    test('sends the source, the target and the roll rule, with a key, and counts who was left', () async {
      when(
        () => students.promote(
          institutionId: any(named: 'institutionId'),
          fromAcademicYearId: any(named: 'fromAcademicYearId'),
          fromClassId: any(named: 'fromClassId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          fromSectionId: any(named: 'fromSectionId'),
          target: any(named: 'target'),
          keepRollNumbers: any(named: 'keepRollNumbers'),
        ),
      ).thenAnswer(
        (_) async => const PromotionResult(
          promotedCount: 12,
          skipped: [SkipReason.alreadyEnrolled, SkipReason.notInSource, SkipReason.alreadyEnrolled],
          warnings: ['SECTION_OVER_CAPACITY'],
        ),
      );
      final bloc = await opened(const PromoteGroup('i1'));
      bloc
        ..add(const PromotionTargetSectionChosen('e3'))
        ..add(const PromotionKeepRollNumbersToggled(value: false))
        ..add(const PromotionSubmitted());
      final done = await bloc.stream.firstWhere((state) => state is PromotionDone) as PromotionDone;
      expect(done.result.promotedCount, 12);
      expect(done.result.skippedFor(SkipReason.alreadyEnrolled), 2);
      expect(done.result.skippedFor(SkipReason.notInSource), 1);
      expect(done.targetName, 'Class 2 · Section A');
      verify(
        () => students.promote(
          institutionId: 'i1',
          fromAcademicYearId: 'y1',
          fromClassId: 'k1',
          idempotencyKey: 'key-1',
          target: _target,
          keepRollNumbers: false,
        ),
      ).called(1);
      await bloc.close();
    });

    test('completes the final class with no target', () async {
      when(
        () => students.promote(
          institutionId: any(named: 'institutionId'),
          fromAcademicYearId: any(named: 'fromAcademicYearId'),
          fromClassId: any(named: 'fromClassId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          fromSectionId: any(named: 'fromSectionId'),
          target: any(named: 'target'),
          keepRollNumbers: any(named: 'keepRollNumbers'),
        ),
      ).thenAnswer((_) async => const PromotionResult(promotedCount: 30));
      final bloc = await opened(const PromoteGroup('i1'));
      bloc
        ..add(const PromotionSourceSectionChosen('e1'))
        ..add(const PromotionTargetSectionChosen('e3'))
        ..add(const PromotionCompletesToggled(value: true))
        ..add(const PromotionSubmitted());
      final done = await bloc.stream.firstWhere((state) => state is PromotionDone) as PromotionDone;
      expect(done.targetName, isNull);
      verify(
        () => students.promote(
          institutionId: 'i1',
          fromAcademicYearId: 'y1',
          fromClassId: 'k1',
          idempotencyKey: 'key-1',
          fromSectionId: 'e1',
        ),
      ).called(1);
      await bloc.close();
    });

    test('a try after a refusal the server keeps is a new attempt, with a new key', () async {
      var refuse = true;
      when(
        () => students.promote(
          institutionId: any(named: 'institutionId'),
          fromAcademicYearId: any(named: 'fromAcademicYearId'),
          fromClassId: any(named: 'fromClassId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          fromSectionId: any(named: 'fromSectionId'),
          target: any(named: 'target'),
          keepRollNumbers: any(named: 'keepRollNumbers'),
        ),
      ).thenAnswer((_) async {
        if (refuse) throw _below;
        return const PromotionResult(promotedCount: 1);
      });
      final bloc = await opened(const PromoteGroup('i1'));
      bloc
        ..add(const PromotionTargetSectionChosen('e3'))
        ..add(const PromotionSubmitted());
      await bloc.stream.firstWhere((state) => state is PromotionReady && state.failure != null);
      refuse = false;
      bloc.add(const PromotionSubmitted());
      await bloc.stream.firstWhere((state) => state is PromotionDone);
      final used = verify(
        () => students.promote(
          institutionId: any(named: 'institutionId'),
          fromAcademicYearId: any(named: 'fromAcademicYearId'),
          fromClassId: any(named: 'fromClassId'),
          idempotencyKey: captureAny(named: 'idempotencyKey'),
          fromSectionId: any(named: 'fromSectionId'),
          target: any(named: 'target'),
          keepRollNumbers: any(named: 'keepRollNumbers'),
        ),
      ).captured;
      expect(used, ['key-1', 'key-2']);
      await bloc.close();
    });

    test(
      'repeats the same attempt with the same key after a failure with no answer, and a changed one with a new',
      () async {
        var refuse = true;
        when(
          () => students.promote(
            institutionId: any(named: 'institutionId'),
            fromAcademicYearId: any(named: 'fromAcademicYearId'),
            fromClassId: any(named: 'fromClassId'),
            idempotencyKey: any(named: 'idempotencyKey'),
            fromSectionId: any(named: 'fromSectionId'),
            target: any(named: 'target'),
            keepRollNumbers: any(named: 'keepRollNumbers'),
          ),
        ).thenAnswer((_) async {
          if (refuse) throw const ApiFailure.network();
          return const PromotionResult(promotedCount: 1);
        });
        final bloc = await opened(const PromoteGroup('i1'));
        bloc
          ..add(const PromotionTargetSectionChosen('e3'))
          ..add(const PromotionSubmitted());
        await bloc.stream.firstWhere((state) => state is PromotionReady && state.failure != null);
        bloc.add(const PromotionSubmitted());
        await bloc.stream.firstWhere((state) => state is PromotionReady && state.failure != null && !state.saving);
        // A change of the attempt is another attempt.
        bloc.add(const PromotionKeepRollNumbersToggled(value: false));
        await bloc.stream.firstWhere((state) => state is PromotionReady && !state.keepRollNumbers);
        refuse = false;
        bloc.add(const PromotionSubmitted());
        await bloc.stream.firstWhere((state) => state is PromotionDone);
        final used = verify(
          () => students.promote(
            institutionId: any(named: 'institutionId'),
            fromAcademicYearId: any(named: 'fromAcademicYearId'),
            fromClassId: any(named: 'fromClassId'),
            idempotencyKey: captureAny(named: 'idempotencyKey'),
            fromSectionId: any(named: 'fromSectionId'),
            target: any(named: 'target'),
            keepRollNumbers: any(named: 'keepRollNumbers'),
          ),
        ).captured;
        expect(used, ['key-1', 'key-1', 'key-2']);
        await bloc.close();
      },
    );

    test('is not started twice while one is on its way', () async {
      final reply = Completer<PromotionResult>();
      when(
        () => students.promote(
          institutionId: any(named: 'institutionId'),
          fromAcademicYearId: any(named: 'fromAcademicYearId'),
          fromClassId: any(named: 'fromClassId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          fromSectionId: any(named: 'fromSectionId'),
          target: any(named: 'target'),
          keepRollNumbers: any(named: 'keepRollNumbers'),
        ),
      ).thenAnswer((_) => reply.future);
      final bloc = await opened(const PromoteGroup('i1'));
      bloc
        ..add(const PromotionTargetSectionChosen('e3'))
        ..add(const PromotionSubmitted())
        ..add(const PromotionSubmitted())
        ..add(const PromotionSourceClassChosen('k2'));
      await Future<void>.delayed(Duration.zero);
      expect(ready(bloc).sourceClassId, 'k1');
      reply.complete(const PromotionResult(promotedCount: 1));
      await bloc.stream.firstWhere((state) => state is PromotionDone);
      verify(
        () => students.promote(
          institutionId: any(named: 'institutionId'),
          fromAcademicYearId: any(named: 'fromAcademicYearId'),
          fromClassId: any(named: 'fromClassId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          fromSectionId: any(named: 'fromSectionId'),
          target: any(named: 'target'),
          keepRollNumbers: any(named: 'keepRollNumbers'),
        ),
      ).called(1);
      await bloc.close();
    });
  });
}
