import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_access_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/staff.dart';
import '../../helpers/subjects.dart';

void main() {
  late MockStaffRepository staff;
  late MockSubjectsRepository subjects;
  late MockInstitutionsRepository institutions;

  // Kavya is based at i1; the Society has two more Institutions.
  final lakeView = summary(id: 'i2', code: 'LVS', name: 'Lake View School', place: null, board: null);
  final hillTop = summary(id: 'i3', code: 'HTS', name: 'Hill Top School', place: null, board: null);

  setUp(() {
    staff = MockStaffRepository();
    subjects = MockSubjectsRepository();
    institutions = MockInstitutionsRepository();
    when(() => subjects.subjects()).thenAnswer((_) async => [art, maths]);
    when(() => institutions.institutions()).thenAnswer((_) async => [summary(), lakeView, hillTop]);
  });

  StaffAccessBloc build({StaffMember? member, bool owner = true}) => StaffAccessBloc(
    staff,
    subjects,
    institutions,
    member: member ?? kavyaWith(subjectIds: ['u1'], institutionIds: ['i2']),
    canChangeInstitutions: owner,
  );

  Future<StaffAccessBloc> opened({StaffMember? member, bool owner = true}) async {
    final bloc = build(member: member, owner: owner);
    addTearDown(bloc.close);
    bloc.add(const StaffAccessStarted());
    await bloc.stream.firstWhere((state) => state is StaffAccessReady);
    return bloc;
  }

  StaffAccessReady ready(StaffAccessBloc bloc) => bloc.state as StaffAccessReady;

  group('starting', () {
    blocTest<StaffAccessBloc, StaffAccessState>(
      'reads the subjects and the Institutions other than the home one, with what the person holds ticked',
      build: build,
      act: (bloc) => bloc.add(const StaffAccessStarted()),
      expect: () => [
        const StaffAccessLoading(),
        StaffAccessReady(
          member: kavyaWith(subjectIds: ['u1'], institutionIds: ['i2']),
          subjects: const [art, maths],
          institutions: [lakeView, hillTop],
          subjectIds: const ['u1'],
          institutionIds: const ['i2'],
        ),
      ],
    );

    blocTest<StaffAccessBloc, StaffAccessState>(
      'does not read the Institutions for a caller who cannot change them',
      build: () => build(owner: false),
      act: (bloc) => bloc.add(const StaffAccessStarted()),
      expect: () => [
        const StaffAccessLoading(),
        isA<StaffAccessReady>().having((s) => s.institutions, 'list', isEmpty),
      ],
      verify: (_) => verifyNever(() => institutions.institutions()),
    );

    blocTest<StaffAccessBloc, StaffAccessState>(
      'keeps the failure for the screen, and starts again on retry',
      setUp: () {
        var calls = 0;
        when(() => subjects.subjects()).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [maths];
        });
      },
      build: build,
      act: (bloc) async {
        bloc.add(const StaffAccessStarted());
        await bloc.stream.firstWhere((state) => state is StaffAccessFailed);
        bloc.add(const StaffAccessStarted());
      },
      expect: () => [
        const StaffAccessLoading(),
        const StaffAccessFailed(ApiFailure.network()),
        const StaffAccessLoading(),
        isA<StaffAccessReady>(),
      ],
    );
  });

  group('ticking', () {
    test('ticks and unticks a subject and an Institution, and says what changed', () async {
      final bloc = await opened();
      expect(ready(bloc).changed(StaffAccessPart.subjects), isFalse);
      bloc
        ..add(const StaffSubjectToggled('u2'))
        ..add(const StaffInstitutionToggled('i2'))
        ..add(const StaffInstitutionToggled('i3'));
      await pumpEventQueue();
      expect(ready(bloc).subjectIds, ['u1', 'u2']);
      expect(ready(bloc).institutionIds, ['i3']);
      expect(ready(bloc).changed(StaffAccessPart.subjects), isTrue);
      expect(ready(bloc).changed(StaffAccessPart.institutions), isTrue);
      bloc.add(const StaffSubjectToggled('u2'));
      await pumpEventQueue();
      expect(ready(bloc).changed(StaffAccessPart.subjects), isFalse);
    });

    test('does not call a list changed when it holds the same entries in another order', () async {
      final bloc = await opened(member: kavyaWith(subjectIds: ['u1', 'u2']));
      bloc
        ..add(const StaffSubjectToggled('u1'))
        ..add(const StaffSubjectToggled('u1'));
      await pumpEventQueue();
      expect(ready(bloc).subjectIds, ['u2', 'u1']);
      expect(ready(bloc).changed(StaffAccessPart.subjects), isFalse);
    });

    test('adds no more than 50 entries to a list, but lets any be taken off', () async {
      final fifty = [for (var i = 0; i < maxStaffAccessChoices; i++) 'u$i'];
      final bloc = await opened(member: kavyaWith(subjectIds: fifty));
      expect(ready(bloc).canAddSubject, isFalse);
      bloc.add(const StaffSubjectToggled('extra'));
      await pumpEventQueue();
      expect(ready(bloc).subjectIds, fifty);
      bloc.add(const StaffSubjectToggled('u3'));
      await pumpEventQueue();
      expect(ready(bloc).subjectIds, hasLength(49));
      expect(ready(bloc).canAddSubject, isTrue);
    });

    test('clears the last refusal once something is ticked', () async {
      when(() => staff.setSubjects(any(), any()))
          .thenThrow(const ApiFailure(statusCode: 409, code: 'SUBJECT_ASSIGNED', message: 'x'));
      final bloc = await opened();
      bloc
        ..add(const StaffSubjectToggled('u1'))
        ..add(const StaffAccessSaved(StaffAccessPart.subjects));
      await bloc.stream.firstWhere((state) => state is StaffAccessReady && state.failure != null);
      bloc.add(const StaffSubjectToggled('u2'));
      await pumpEventQueue();
      expect(ready(bloc).failure, isNull);
      expect(ready(bloc).failedPart, isNull);
    });
  });

  group('saving', () {
    test('sends the ticked subjects and takes the staff member the API answers with', () async {
      final answer = kavyaWith(subjectIds: ['u1', 'u2'], institutionIds: ['i2']);
      when(() => staff.setSubjects('f1', ['u1', 'u2'])).thenAnswer((_) async => answer);
      final bloc = await opened();
      bloc
        ..add(const StaffSubjectToggled('u2'))
        ..add(const StaffAccessSaved(StaffAccessPart.subjects));
      await bloc.stream.firstWhere((state) => state is StaffAccessReady && state.member == answer);
      expect(ready(bloc).saving, isNull);
      expect(ready(bloc).changed(StaffAccessPart.subjects), isFalse);
      verifyNever(() => staff.setInstitutions(any(), any()));
    });

    test('sends the ticked Institutions, and leaves the subjects ticked and not saved as they are', () async {
      final answer = kavyaWith(subjectIds: ['u1'], institutionIds: ['i3']);
      when(() => staff.setInstitutions('f1', ['i3'])).thenAnswer((_) async => answer);
      final bloc = await opened();
      bloc
        ..add(const StaffSubjectToggled('u2'))
        ..add(const StaffInstitutionToggled('i2'))
        ..add(const StaffInstitutionToggled('i3'))
        ..add(const StaffAccessSaved(StaffAccessPart.institutions));
      await bloc.stream.firstWhere((state) => state is StaffAccessReady && state.member == answer);
      expect(ready(bloc).institutionIds, ['i3']);
      expect(ready(bloc).subjectIds, ['u1', 'u2']);
      expect(ready(bloc).changed(StaffAccessPart.subjects), isTrue);
    });

    test('sends the ticked subjects, and leaves the Institutions ticked and not saved as they are', () async {
      final answer = kavyaWith(subjectIds: ['u1', 'u2'], institutionIds: ['i2']);
      when(() => staff.setSubjects('f1', ['u1', 'u2'])).thenAnswer((_) async => answer);
      final bloc = await opened();
      bloc
        ..add(const StaffSubjectToggled('u2'))
        ..add(const StaffInstitutionToggled('i3'))
        ..add(const StaffAccessSaved(StaffAccessPart.subjects));
      await bloc.stream.firstWhere((state) => state is StaffAccessReady && state.member == answer);
      expect(ready(bloc).subjectIds, ['u1', 'u2']);
      expect(ready(bloc).institutionIds, ['i2', 'i3']);
      expect(ready(bloc).changed(StaffAccessPart.institutions), isTrue);
    });

    test('sends nothing for a list that was not changed', () async {
      final bloc = await opened();
      bloc.add(const StaffAccessSaved(StaffAccessPart.subjects));
      await pumpEventQueue();
      verifyNever(() => staff.setSubjects(any(), any()));
    });

    test('sends nothing while a save is on its way', () async {
      final held = Completer<StaffMember>();
      when(() => staff.setSubjects(any(), any())).thenAnswer((_) => held.future);
      final bloc = await opened();
      bloc
        ..add(const StaffSubjectToggled('u2'))
        ..add(const StaffInstitutionToggled('i3'))
        ..add(const StaffAccessSaved(StaffAccessPart.subjects));
      await bloc.stream.firstWhere((state) => state is StaffAccessReady && state.saving != null);
      bloc
        ..add(const StaffAccessSaved(StaffAccessPart.subjects))
        ..add(const StaffAccessSaved(StaffAccessPart.institutions));
      await pumpEventQueue();
      verify(() => staff.setSubjects(any(), any())).called(1);
      verifyNever(() => staff.setInstitutions(any(), any()));
      held.complete(kavyaWith(subjectIds: ['u1', 'u2']));
    });

    for (final (part, code) in [
      (StaffAccessPart.subjects, 'SUBJECT_ASSIGNED'),
      (StaffAccessPart.institutions, 'ADMIN_ACCESS_HELD'),
    ]) {
      test('keeps what is ticked, with the failure of the list it was for, when $code refuses it', () async {
        final failure = ApiFailure(statusCode: 409, code: code, message: 'x');
        when(() => staff.setSubjects(any(), any())).thenThrow(failure);
        when(() => staff.setInstitutions(any(), any())).thenThrow(failure);
        final bloc = await opened();
        bloc
          ..add(const StaffSubjectToggled('u1'))
          ..add(const StaffInstitutionToggled('i2'))
          ..add(StaffAccessSaved(part));
        await bloc.stream.firstWhere((state) => state is StaffAccessReady && state.failure != null);
        expect(ready(bloc).failure, failure);
        expect(ready(bloc).failedPart, part);
        expect(ready(bloc).saving, isNull);
        expect(ready(bloc).subjectIds, isEmpty);
        expect(ready(bloc).institutionIds, isEmpty);
      });
    }

    test('keeps a choice made while the save was on its way, when the save is refused', () async {
      final held = Completer<StaffMember>();
      when(() => staff.setSubjects(any(), any())).thenAnswer((_) => held.future);
      final bloc = await opened();
      bloc
        ..add(const StaffSubjectToggled('u2'))
        ..add(const StaffAccessSaved(StaffAccessPart.subjects));
      await bloc.stream.firstWhere((state) => state is StaffAccessReady && state.saving != null);
      bloc.add(const StaffInstitutionToggled('i3'));
      await pumpEventQueue();
      held.completeError(const ApiFailure(statusCode: 409, code: 'SUBJECT_ASSIGNED', message: 'x'));
      await bloc.stream.firstWhere((state) => state is StaffAccessReady && state.failure != null);
      expect(ready(bloc).institutionIds, ['i2', 'i3']);
    });
  });
}
