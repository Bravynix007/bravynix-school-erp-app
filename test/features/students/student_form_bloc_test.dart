import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/masters/domain/place_choice.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/student_draft.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_form_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/classes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/sections.dart';

const _down = ApiFailure(statusCode: 503, code: 'UNAVAILABLE', message: 'x');
const _taken = ApiFailure(statusCode: 409, code: 'ROLL_NUMBER_TAKEN', message: 'x');
const _saved = StudentSaved(
  Student(id: 'p1', institutionId: 'i1', firstName: 'Asha'),
  warnings: ['SECTION_OVER_CAPACITY'],
);

const _india = PlaceChoice(countryId: 'k1', stateId: 's1', cityId: 'y1');

GuardianTexts _texts({String first = 'Ravi', String number = '9845012345'}) =>
    GuardianTexts(firstName: first, countryCode: '91', number: number);

void main() {
  late MockStudentsRepository students;
  late MockAcademicYearsRepository years;
  late MockClassesRepository classes;
  late MockSectionsRepository sections;

  setUpAll(() {
    registerFallbackValue(
      const StudentDraft(
        firstName: '',
        mobile: Phone(countryCode: '', number: ''),
      ),
    );
    registerFallbackValue(const EnrolmentDraft(academicYearId: '', classId: '', sectionId: '', rollNumber: ''));
    registerFallbackValue(const IdentityDraft());
  });
  setUp(() {
    students = MockStudentsRepository();
    years = MockAcademicYearsRepository();
    classes = MockClassesRepository();
    sections = MockSectionsRepository();
    when(() => years.years('i1')).thenAnswer((_) async => [earlierYear, currentYear]);
    when(() => classes.classes('i1')).thenAnswer((_) async => [class1, pucClass]);
    when(() => sections.sections('k1')).thenAnswer((_) async => [sectionA, sectionB]);
  });

  StudentFormBloc build() => StudentFormBloc(
    students,
    SectionOptionsSource(years: years, classes: classes, sections: sections),
    'i1',
  );

  /// The bloc opened, then [act].
  Future<StudentFormBloc> opened() async {
    final bloc = build()..add(const StudentFormStarted());
    await bloc.stream.firstWhere((state) => state is StudentFormReady);
    return bloc;
  }

  StudentFormReady ready(StudentFormBloc bloc) => bloc.state as StudentFormReady;

  group('opening', () {
    blocTest<StudentFormBloc, StudentFormState>(
      'chooses the current year, and starts with one guardian who is the primary one',
      build: build,
      act: (bloc) => bloc.add(const StudentFormStarted()),
      expect: () => [
        const StudentFormLoading(),
        isA<StudentFormReady>()
            .having((s) => s.yearId, 'year', 'y1')
            .having((s) => s.classId, 'class', isNull)
            .having((s) => s.sections, 'sections', isEmpty)
            .having((s) => s.guardians, 'guardians', const [
              GuardianEntry(0, GuardianTexts(countryCode: '91'), isPrimary: true),
            ])
            .having((s) => s.options.classes.map((c) => c.id), 'classes', ['k1']),
      ],
    );

    blocTest<StudentFormBloc, StudentFormState>(
      'fails when the years and sections cannot be read, and reads them again on Try again',
      setUp: () {
        var calls = 0;
        when(() => years.years('i1')).thenAnswer((_) async {
          if (calls++ == 0) throw _down;
          return [currentYear];
        });
      },
      build: build,
      act: (bloc) async {
        bloc.add(const StudentFormStarted());
        await bloc.stream.firstWhere((state) => state is StudentFormFailed);
        bloc.add(const StudentFormStarted());
      },
      expect: () => [
        const StudentFormLoading(),
        const StudentFormFailed(_down),
        const StudentFormLoading(),
        isA<StudentFormReady>(),
      ],
    );

    test('ignores a choice made before the form is ready', () async {
      final bloc = build()..add(const StudentGenderChosen(Gender.male));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, const StudentFormLoading());
    });
  });

  group('choices', () {
    test('keep the gender, blood group and dates', () async {
      final bloc = await opened();
      bloc
        ..add(const StudentGenderChosen(Gender.female))
        ..add(const StudentBloodGroupChosen('O+'))
        ..add(const StudentBirthDateChosen('2014-03-09'))
        ..add(const StudentAdmissionDateChosen('2026-06-01'))
        ..add(const StudentPhotoChosen('f1'))
        ..add(const StudentYearChosen('y0'));
      await Future<void>.delayed(Duration.zero);
      final state = ready(bloc);
      expect(
        [state.gender, state.bloodGroup, state.dateOfBirth, state.admissionDate, state.photoFileId, state.yearId],
        [
          Gender.female,
          'O+',
          '2014-03-09',
          '2026-06-01',
          'f1',
          'y0',
        ],
      );
      bloc
        ..add(const StudentGenderChosen(null))
        ..add(const StudentPhotoChosen(null));
      await Future<void>.delayed(Duration.zero);
      expect([ready(bloc).gender, ready(bloc).photoFileId], [null, null]);
    });

    test('offer the sections of the class chosen, and let go a section when the class changes', () async {
      final bloc = await opened()
        ..add(const StudentClassChosen('k1'))
        ..add(const StudentSectionChosen('e2'));
      await Future<void>.delayed(Duration.zero);
      expect(ready(bloc).sections.map((section) => section.id), ['e1', 'e2']);
      expect(ready(bloc).sectionId, 'e2');
      // The same class again keeps the section; another class lets it go.
      bloc.add(const StudentClassChosen('k1'));
      await Future<void>.delayed(Duration.zero);
      expect(ready(bloc).sectionId, 'e2');
      bloc.add(const StudentClassChosen('k9'));
      await Future<void>.delayed(Duration.zero);
      expect([ready(bloc).classId, ready(bloc).sectionId, ready(bloc).sections], ['k9', null, isEmpty]);
    });
  });

  group('guardians', () {
    test('are added up to five, each with the dial code, and none is primary but the first', () async {
      final bloc = await opened();
      for (var i = 0; i < 6; i++) {
        bloc.add(const StudentGuardianAdded());
      }
      await Future<void>.delayed(Duration.zero);
      final state = ready(bloc);
      expect(state.guardians.map((entry) => entry.id), [0, 1, 2, 3, 4]);
      expect(state.guardians.map((entry) => entry.isPrimary), [true, false, false, false, false]);
      expect(state.guardians.last.texts.countryCode, '91');
      expect(state.canAddGuardian, isFalse);
    });

    test('keep what is typed, the relation and the emergency mark on their own row', () async {
      final bloc = await opened()
        ..add(const StudentGuardianAdded())
        ..add(StudentGuardianEdited(1, _texts(first: 'Meera')))
        ..add(const StudentGuardianRelationChosen(1, GuardianRelation.mother))
        ..add(const StudentGuardianEmergencyChosen(1, isEmergencyContact: true));
      await Future<void>.delayed(Duration.zero);
      final rows = ready(bloc).guardians;
      expect(rows[0], const GuardianEntry(0, GuardianTexts(countryCode: '91'), isPrimary: true));
      expect(rows[1].texts.firstName, 'Meera');
      expect([rows[1].relation, rows[1].isEmergencyContact], [GuardianRelation.mother, true]);
      bloc.add(const StudentGuardianRelationChosen(1, null));
      await Future<void>.delayed(Duration.zero);
      expect(ready(bloc).guardians[1].relation, isNull);
    });

    test('have exactly one primary: choosing one takes the mark from the other', () async {
      final bloc = await opened()
        ..add(const StudentGuardianAdded())
        ..add(const StudentGuardianPrimaryChosen(1));
      await Future<void>.delayed(Duration.zero);
      expect(ready(bloc).guardians.map((entry) => entry.isPrimary), [false, true]);
    });

    test('are removed, but never the last, and the primary mark goes to the first left', () async {
      final bloc = await opened()
        ..add(const StudentGuardianAdded())
        ..add(const StudentGuardianAdded())
        ..add(const StudentGuardianRemoved(0));
      await Future<void>.delayed(Duration.zero);
      expect(ready(bloc).guardians.map((entry) => (entry.id, entry.isPrimary)), [(1, true), (2, false)]);
      bloc
        ..add(const StudentGuardianRemoved(2))
        ..add(const StudentGuardianRemoved(1));
      await Future<void>.delayed(Duration.zero);
      expect(ready(bloc).guardians.map((entry) => entry.id), [1]);
      // A removed row's number is not used again, so a row keeps its place on screen.
      bloc.add(const StudentGuardianAdded());
      await Future<void>.delayed(Duration.zero);
      expect(ready(bloc).guardians.map((entry) => entry.id), [1, 3]);
    });

    test('keep the primary mark where it is when another guardian is removed', () async {
      final bloc = await opened()
        ..add(const StudentGuardianAdded())
        ..add(const StudentGuardianPrimaryChosen(1))
        ..add(const StudentGuardianRemoved(0));
      await Future<void>.delayed(Duration.zero);
      expect(ready(bloc).guardians.map((entry) => (entry.id, entry.isPrimary)), [(1, true)]);
    });
  });

  group('saving', () {
    Future<StudentFormBloc> filled() async {
      final bloc = await opened()
        ..add(const StudentGenderChosen(Gender.female))
        ..add(const StudentBloodGroupChosen('O+'))
        ..add(const StudentBirthDateChosen('2014-03-09'))
        ..add(const StudentAdmissionDateChosen('2026-06-01'))
        ..add(const StudentPhotoChosen('f1'))
        ..add(const StudentClassChosen('k1'))
        ..add(const StudentSectionChosen('e1'))
        ..add(StudentGuardianEdited(0, _texts()))
        ..add(const StudentGuardianRelationChosen(0, GuardianRelation.father));
      await Future<void>.delayed(Duration.zero);
      return bloc;
    }

    const texts = StudentTexts(
      firstName: ' Asha ',
      lastName: 'Rao',
      admissionNo: ' A-014 ',
      mobileCountryCode: '+91',
      mobileNumber: '98765 01234',
      alternateNumber: '98765 00000',
      nationality: 'Indian',
      addressLine1: '12 Lake Road',
      pincode: '560001',
      rollNumber: ' 14 ',
      aadhaar: '2345 6789-0123',
      birthCertificate: ' BC-1 ',
    );

    test('adds the student with what was typed and chosen, trimmed, and says it was saved', () async {
      when(
        () => students.create(
          any(),
          any(),
          enrolment: any(named: 'enrolment'),
          guardians: any(named: 'guardians'),
          identity: any(named: 'identity'),
        ),
      ).thenAnswer((_) async => _saved);
      final bloc = await filled();
      final states = <StudentFormState>[];
      final subscription = bloc.stream.listen(states.add);
      bloc.add(const StudentFormSubmitted(texts, _india));
      await bloc.stream.firstWhere((state) => state is StudentFormSaved);
      await subscription.cancel();
      expect(states.first, isA<StudentFormReady>().having((s) => s.saving, 'saving', true));
      expect(states.last, const StudentFormSaved(_saved));
      final captured = verify(
        () => students.create(
          captureAny(),
          captureAny(),
          enrolment: captureAny(named: 'enrolment'),
          guardians: captureAny(named: 'guardians'),
          identity: captureAny(named: 'identity'),
        ),
      ).captured;
      expect(captured[0], 'i1');
      expect(
        captured[1],
        const StudentDraft(
          firstName: 'Asha',
          lastName: 'Rao',
          gender: Gender.female,
          dateOfBirth: '2014-03-09',
          bloodGroup: 'O+',
          nationality: 'Indian',
          photoFileId: 'f1',
          admissionNo: 'A-014',
          admissionDate: '2026-06-01',
          mobile: Phone(countryCode: '91', number: '9876501234'),
          alternateNumber: '9876500000',
          address: Address(line1: '12 Lake Road', countryId: 'k1', stateId: 's1', cityId: 'y1', pincode: '560001'),
        ),
      );
      expect(
        captured[2],
        const EnrolmentDraft(academicYearId: 'y1', classId: 'k1', sectionId: 'e1', rollNumber: '14'),
      );
      expect(captured[3], const [
        GuardianDraft(
          firstName: 'Ravi',
          relation: GuardianRelation.father,
          phone: Phone(countryCode: '91', number: '9845012345'),
          isPrimary: true,
          isEmergencyContact: false,
        ),
      ]);
      expect(captured[4], const IdentityDraft(aadhaarNumber: '234567890123', birthCertificateNumber: 'BC-1'));
    });

    /// Every call of `create` is answered with [_saved]; [delay] makes it take a while.
    void createdAs({Duration delay = Duration.zero}) =>
        when(
          () => students.create(
            any(),
            any(),
            enrolment: any(named: 'enrolment'),
            guardians: any(named: 'guardians'),
            identity: any(named: 'identity'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(delay);
          return _saved;
        });

    test('sends no identity when none is typed, and what is optional as it was left', () async {
      createdAs();
      final bloc = await filled();
      bloc.add(
        const StudentFormSubmitted(
          StudentTexts(firstName: 'Asha', mobileNumber: '9876501234', rollNumber: '14'),
          PlaceChoice(),
        ),
      );
      await bloc.stream.firstWhere((state) => state is StudentFormSaved);
      final captured = verify(
        () => students.create(
          captureAny(),
          captureAny(),
          enrolment: captureAny(named: 'enrolment'),
          guardians: captureAny(named: 'guardians'),
          identity: captureAny(named: 'identity'),
        ),
      ).captured;
      expect(captured[4], const IdentityDraft());
      expect((captured[1] as StudentDraft).address, const Address());
    });

    test('says what is required and was left empty, under the field, and sends nothing', () async {
      final bloc = await opened();
      bloc
        ..add(const StudentGuardianAdded())
        ..add(const StudentGuardianEdited(1, GuardianTexts(firstName: ' ', countryCode: '91', number: '9845012345')));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const StudentFormSubmitted(StudentTexts(firstName: ' '), PlaceChoice()));
      await bloc.stream.firstWhere((state) => state is StudentFormReady && state.failure != null);
      final state = ready(bloc);
      expect(state.saving, isFalse);
      expect(state.failedGuardianIds, [0, 1]);
      expect(state.failure!.fieldErrors.map((error) => [error.field, error.code]), [
        ['firstName', 'REQUIRED'],
        ['mobile.number', 'REQUIRED'],
        ['enrolment.classId', 'REQUIRED'],
        ['enrolment.sectionId', 'REQUIRED'],
        ['enrolment.rollNumber', 'REQUIRED'],
        ['guardians[0].firstName', 'REQUIRED'],
        ['guardians[0].relation', 'REQUIRED'],
        ['guardians[0].phone.number', 'REQUIRED'],
        ['guardians[1].firstName', 'REQUIRED'],
        ['guardians[1].relation', 'REQUIRED'],
      ]);
      verifyZeroInteractions(students);
    });

    test('asks for the year when none is chosen', () async {
      final bloc = await filled()
        ..add(const StudentYearChosen(null));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const StudentFormSubmitted(texts, _india));
      await bloc.stream.firstWhere((state) => state is StudentFormReady && state.failure != null);
      expect(ready(bloc).failure!.fieldErrors.map((error) => error.field), ['enrolment.academicYearId']);
    });

    for (final typed in ['1234 5678', '0345 6789 0123']) {
      test('refuses the Aadhaar number "$typed", and sends nothing', () async {
        final bloc = await filled();
        bloc.add(
          StudentFormSubmitted(
            StudentTexts(firstName: 'Asha', mobileNumber: '9876501234', rollNumber: '1', aadhaar: typed),
            _india,
          ),
        );
        await bloc.stream.firstWhere((state) => state is StudentFormReady && state.failure != null);
        expect(ready(bloc).failure!.fieldErrors.map((error) => [error.field, error.code]), [
          ['identity.aadhaarNumber', 'INVALID_AADHAAR'],
        ]);
        verifyZeroInteractions(students);
      });
    }

    test('sends a guardian marked as an emergency contact as one', () async {
      createdAs();
      final bloc = await filled()
        ..add(const StudentGuardianEmergencyChosen(0, isEmergencyContact: true));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const StudentFormSubmitted(texts, _india));
      await bloc.stream.firstWhere((state) => state is StudentFormSaved);
      final captured = verify(
        () => students.create(
          any(),
          any(),
          enrolment: any(named: 'enrolment'),
          guardians: captureAny(named: 'guardians'),
          identity: any(named: 'identity'),
        ),
      ).captured;
      expect((captured.single as List<GuardianDraft>).single.isEmergencyContact, isTrue);
    });

    test('keeps the form and says why a save was refused, with the rows it sent', () async {
      when(
        () => students.create(
          any(),
          any(),
          enrolment: any(named: 'enrolment'),
          guardians: any(named: 'guardians'),
          identity: any(named: 'identity'),
        ),
      ).thenThrow(_taken);
      final bloc = await filled()
        ..add(const StudentGuardianAdded());
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(StudentGuardianEdited(1, _texts(first: 'Sita')))
        ..add(const StudentGuardianRelationChosen(1, GuardianRelation.mother));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const StudentFormSubmitted(texts, _india));
      await bloc.stream.firstWhere((state) => state is StudentFormReady && state.failure != null);
      final state = ready(bloc);
      expect(
        [state.saving, state.failure, state.failedGuardianIds],
        [
          false,
          _taken,
          [0, 1],
        ],
      );
      expect(state.classId, 'k1');
    });

    test('goes on with a second save once the first answered, and not while it is out', () async {
      var calls = 0;
      when(
        () => students.create(
          any(),
          any(),
          enrolment: any(named: 'enrolment'),
          guardians: any(named: 'guardians'),
          identity: any(named: 'identity'),
        ),
      ).thenAnswer((_) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return _saved;
      });
      final bloc = await filled();
      bloc
        ..add(const StudentFormSubmitted(texts, _india))
        ..add(const StudentFormSubmitted(texts, _india));
      await bloc.stream.firstWhere((state) => state is StudentFormSaved);
      expect(calls, 1);
    });

    test(
      'names the rows the save sent when a row is removed while it is out, and keeps what was changed meanwhile',
      () async {
        when(
          () => students.create(
            any(),
            any(),
            enrolment: any(named: 'enrolment'),
            guardians: any(named: 'guardians'),
            identity: any(named: 'identity'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          throw _taken;
        });
        final bloc = await filled()
          ..add(const StudentGuardianAdded());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(StudentGuardianEdited(1, _texts(first: 'Sita')))
          ..add(const StudentGuardianRelationChosen(1, GuardianRelation.mother))
          ..add(const StudentFormSubmitted(texts, _india));
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const StudentGuardianRemoved(1))
          ..add(const StudentClassChosen(null))
          ..add(const StudentGenderChosen(Gender.other));
        await bloc.stream.firstWhere((state) => state is StudentFormReady && state.failure != null);
        final state = ready(bloc);
        // The API names the rows the save sent, 0 and 1, though row 1 is gone now.
        expect(state.failedGuardianIds, [0, 1]);
        expect(state.guardians.map((entry) => entry.id), [0]);
        expect([state.classId, state.gender], [null, Gender.other]);
      },
    );
  });
}
