import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/place_choice.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_draft.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_form_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/staff.dart';

const _lowerPrimary = MasterEntry(id: 'c1', name: 'Lower Primary');
const _place = PlaceChoice(countryId: 'k1', stateId: 's1', cityId: 'y1');
const _texts = StaffTexts(
  firstName: ' Ravi ',
  email: ' ravi@example.com ',
  mobileCountryCode: '91',
  mobileNumber: '98765 43210',
);

void main() {
  late MockStaffRepository staff;
  late MockMastersRepository masters;

  setUpAll(() {
    registerFallbackValue(raviDraft);
    registerFallbackValue(MasterType.countries);
  });

  setUp(() {
    staff = MockStaffRepository();
    masters = MockMastersRepository();
    when(() => masters.entries(MasterType.classCategories)).thenAnswer((_) async => [_lowerPrimary]);
    when(() => masters.entries(MasterType.designations)).thenAnswer((_) async => [designationEntry, otherDesignation]);
  });

  StaffFormBloc add() => StaffFormBloc(staff, masters, institutionId: 'i1');
  StaffFormBloc edit() => StaffFormBloc(staff, masters, staffId: 'f1');

  Future<void> started(StaffFormBloc bloc) async {
    bloc.add(const StaffFormStarted());
    await bloc.stream.firstWhere((state) => state is StaffFormReady);
  }

  StaffFormReady ready(StaffFormBloc bloc) => bloc.state as StaffFormReady;

  test('adds at an Institution, or edits one staff member, never both and never neither', () {
    expect(() => StaffFormBloc(staff, masters), throwsA(isA<AssertionError>()));
    expect(() => StaffFormBloc(staff, masters, institutionId: 'i1', staffId: 'f1'), throwsA(isA<AssertionError>()));
  });

  group('adding', () {
    blocTest<StaffFormBloc, StaffFormState>(
      'starts empty, with the categories and designations to choose from',
      build: add,
      act: (bloc) => bloc.add(const StaffFormStarted()),
      expect: () => [
        const StaffFormLoading(),
        const StaffFormReady(
          categories: [_lowerPrimary],
          designations: [designationEntry, otherDesignation],
          educations: [],
          contacts: [],
          nextRowId: 0,
        ),
      ],
      verify: (_) => verifyNever(() => staff.member(any())),
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'keeps the failure for the screen, and starts again on retry',
      build: add,
      setUp: () {
        var calls = 0;
        when(() => masters.entries(MasterType.classCategories)).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [_lowerPrimary];
        });
      },
      act: (bloc) async {
        bloc.add(const StaffFormStarted());
        await bloc.stream.firstWhere((state) => state is StaffFormFailed);
        bloc.add(const StaffFormStarted());
      },
      expect: () => [
        const StaffFormLoading(),
        const StaffFormFailed(ApiFailure.network()),
        const StaffFormLoading(),
        isA<StaffFormReady>(),
      ],
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'keeps what is chosen',
      build: add,
      act: (bloc) async {
        await started(bloc);
        bloc
          ..add(const StaffGenderChosen(Gender.female))
          ..add(const StaffBloodGroupChosen('O+'))
          ..add(const StaffBirthDateChosen('1990-04-17'))
          ..add(const StaffJoiningDateChosen('2020-06-01'))
          ..add(const StaffResignationDateChosen('2026-03-31'))
          ..add(const StaffEmploymentTypeChosen(EmploymentType.contract))
          ..add(const StaffCategoryChosen('c1'))
          ..add(const StaffDesignationChosen('d1'))
          ..add(const StaffPhotoChosen('p2'));
      },
      skip: 2,
      verify: (bloc) {
        final state = ready(bloc);
        expect(state.gender, Gender.female);
        expect(state.bloodGroup, 'O+');
        expect(state.dateOfBirth, '1990-04-17');
        expect(state.joiningDate, '2020-06-01');
        expect(state.resignationDate, '2026-03-31');
        expect(state.employmentType, EmploymentType.contract);
        expect(state.categoryId, 'c1');
        expect(state.designationId, 'd1');
        expect(state.photoFileId, 'p2');
      },
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'clears a choice, a date and a photo that was removed',
      build: add,
      act: (bloc) async {
        await started(bloc);
        bloc
          ..add(const StaffGenderChosen(Gender.female))
          ..add(const StaffGenderChosen(null))
          ..add(const StaffBirthDateChosen('1990-04-17'))
          ..add(const StaffBirthDateChosen(null))
          ..add(const StaffPhotoChosen('p2'))
          ..add(const StaffPhotoChosen(null));
      },
      verify: (bloc) {
        final state = ready(bloc);
        expect([state.gender, state.dateOfBirth, state.photoFileId], [null, null, null]);
      },
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'sends what was typed, trimmed, and the chosen place, then reports the staff member made',
      build: add,
      setUp: () => when(() => staff.create(any(), any())).thenAnswer((_) async => raviMember),
      act: (bloc) async {
        await started(bloc);
        bloc
          ..add(const StaffCategoryChosen('c1'))
          ..add(const StaffGenderChosen(Gender.male))
          ..add(const StaffPhotoChosen('p2'))
          ..add(
            const StaffFormSubmitted(
              StaffTexts(
                firstName: ' Ravi ',
                lastName: '  ',
                email: ' ravi@example.com ',
                mobileCountryCode: ' +91 ',
                mobileNumber: '98765 43210',
                alternateNumber: ' 98765 00000 ',
                nationality: ' Indian ',
                employeeCode: ' T-020 ',
                addressLine1: ' 3 Hill Street ',
                pincode: '   ',
              ),
              _place,
            ),
          );
        await bloc.stream.firstWhere((state) => state is StaffFormSaved);
      },
      verify: (_) {
        final draft = verify(() => staff.create('i1', captureAny())).captured.single as StaffDraft;
        expect(
          draft,
          const StaffDraft(
            email: 'ravi@example.com',
            firstName: 'Ravi',
            employeeCode: 'T-020',
            gender: Gender.male,
            nationality: 'Indian',
            photoFileId: 'p2',
            classCategoryId: 'c1',
            mobile: mobile,
            alternateNumber: '9876500000',
            address: Address(
              line1: '3 Hill Street',
              countryId: 'k1',
              stateId: 's1',
              cityId: 'y1',
            ),
          ),
        );
      },
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'sends no category when none was chosen, and a mobile with no number as it is, so the API names the fields',
      build: add,
      setUp: () => when(() => staff.create(any(), any())).thenAnswer((_) async => raviMember),
      act: (bloc) async {
        await started(bloc);
        bloc.add(const StaffFormSubmitted(StaffTexts(firstName: 'Ravi', mobileCountryCode: '91'), PlaceChoice()));
        await bloc.stream.firstWhere((state) => state is StaffFormSaved);
      },
      verify: (_) {
        final draft = verify(() => staff.create(any(), captureAny())).captured.single as StaffDraft;
        expect(draft.classCategoryId, isEmpty);
        // The dial code that was typed stays, so the API names only the number.
        expect(draft.mobile, const Phone(countryCode: '91', number: ''));
      },
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'keeps the form, with the failure, when the save is refused',
      build: add,
      setUp: () => when(() => staff.create(any(), any())).thenThrow(
        const ApiFailure(
          statusCode: 409,
          code: 'EMPLOYEE_ID_TAKEN',
          message: 'x',
          fieldErrors: [FieldError(field: 'employeeCode', code: 'DUPLICATE', message: 'Taken')],
        ),
      ),
      act: (bloc) async {
        await started(bloc);
        bloc.add(const StaffFormSubmitted(_texts, _place));
      },
      skip: 2,
      expect: () => [
        isA<StaffFormReady>().having((s) => s.saving, 'saving', isTrue),
        isA<StaffFormReady>()
            .having((s) => s.saving, 'saving', isFalse)
            .having((s) => s.failure?.code, 'failure', 'EMPLOYEE_ID_TAKEN'),
      ],
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'does not save twice while a save is on its way',
      build: add,
      setUp: () => when(() => staff.create(any(), any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return raviMember;
      }),
      act: (bloc) async {
        await started(bloc);
        bloc
          ..add(const StaffFormSubmitted(_texts, _place))
          ..add(const StaffFormSubmitted(_texts, _place));
      },
      verify: (_) => verify(() => staff.create(any(), any())).called(1),
      expect: () => anything,
    );
  });

  group('education lines', () {
    blocTest<StaffFormBloc, StaffFormState>(
      'adds rows with their own numbers, edits one, and removes one without moving the others',
      build: add,
      act: (bloc) async {
        await started(bloc);
        bloc
          ..add(const StaffEducationAdded())
          ..add(const StaffEducationAdded())
          ..add(const StaffEducationAdded())
          ..add(const StaffEducationEdited(1, EducationTexts(degree: 'B.Ed')))
          ..add(const StaffEducationRemoved(0))
          ..add(const StaffEducationAdded());
      },
      verify: (bloc) {
        final state = ready(bloc);
        expect([for (final entry in state.educations) entry.id], [1, 2, 3]);
        expect(state.educations.first.texts.degree, 'B.Ed');
        expect(state.nextRowId, 4);
      },
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'stops adding at 20 lines',
      build: add,
      act: (bloc) async {
        await started(bloc);
        for (var i = 0; i < maxEducations + 1; i++) {
          bloc.add(const StaffEducationAdded());
        }
      },
      verify: (bloc) {
        expect(ready(bloc).educations, hasLength(maxEducations));
        expect(ready(bloc).canAddEducation, isFalse);
      },
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'sends each line trimmed, with the year as a number and an empty part as not set',
      build: add,
      setUp: () => when(() => staff.create(any(), any())).thenAnswer((_) async => raviMember),
      act: (bloc) async {
        await started(bloc);
        bloc
          ..add(const StaffEducationAdded())
          ..add(
            const StaffEducationEdited(
              0,
              EducationTexts(
                degree: ' B.Ed ',
                qualification: ' ',
                institutionName: ' Mysore ',
                yearOfPassing: ' 2014 ',
              ),
            ),
          )
          ..add(const StaffFormSubmitted(_texts, _place));
        await bloc.stream.firstWhere((state) => state is StaffFormSaved);
      },
      verify: (_) {
        final draft = verify(() => staff.create(any(), captureAny())).captured.single as StaffDraft;
        expect(draft.educations, const [Education(degree: 'B.Ed', institutionName: 'Mysore', yearOfPassing: 2014)]);
      },
    );
  });

  group('emergency contacts', () {
    blocTest<StaffFormBloc, StaffFormState>(
      'starts a new contact at the same dial code a new mobile starts at, so a number alone is a whole phone',
      build: add,
      act: (bloc) async {
        await started(bloc);
        bloc.add(const StaffContactAdded());
      },
      verify: (bloc) => expect(ready(bloc).contacts.single.texts.countryCode, Phone.indiaDialCode),
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'makes one contact the primary, which takes the mark from another, and removes one',
      build: add,
      act: (bloc) async {
        await started(bloc);
        bloc
          ..add(const StaffContactAdded())
          ..add(const StaffContactAdded())
          ..add(const StaffContactPrimaryChosen(0, isPrimary: true))
          ..add(const StaffContactPrimaryChosen(1, isPrimary: true));
      },
      verify: (bloc) => expect([for (final entry in ready(bloc).contacts) entry.isPrimary], [false, true]),
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'takes the mark off, keeps it through an edit, and drops it with the row',
      build: add,
      act: (bloc) async {
        await started(bloc);
        bloc
          ..add(const StaffContactAdded())
          ..add(const StaffContactPrimaryChosen(0, isPrimary: true))
          ..add(const StaffContactEdited(0, ContactTexts(contactName: 'Anil')));
        await bloc.stream.firstWhere(
          (state) => state is StaffFormReady && state.contacts.first.texts.contactName == 'Anil',
        );
        expect(ready(bloc).contacts.single.isPrimary, isTrue);
        bloc.add(const StaffContactPrimaryChosen(0, isPrimary: false));
        await bloc.stream.firstWhere((state) => state is StaffFormReady && !state.contacts.first.isPrimary);
        bloc
          ..add(const StaffContactPrimaryChosen(0, isPrimary: true))
          ..add(const StaffContactRemoved(0));
      },
      verify: (bloc) => expect(ready(bloc).contacts, isEmpty),
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'stops adding at 10 contacts',
      build: add,
      act: (bloc) async {
        await started(bloc);
        for (var i = 0; i < maxEmergencyContacts + 1; i++) {
          bloc.add(const StaffContactAdded());
        }
      },
      verify: (bloc) {
        expect(ready(bloc).contacts, hasLength(maxEmergencyContacts));
        expect(ready(bloc).canAddContact, isFalse);
      },
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'sends each contact with its phone as typed, and a number left out as empty so the API names it',
      build: add,
      setUp: () => when(() => staff.create(any(), any())).thenAnswer((_) async => raviMember),
      act: (bloc) async {
        await started(bloc);
        bloc
          ..add(const StaffContactAdded())
          ..add(const StaffContactAdded())
          ..add(
            const StaffContactEdited(
              0,
              ContactTexts(
                contactName: ' Anil ',
                relation: ' Father ',
                countryCode: ' +91 ',
                number: '98765 11111',
                alternateNumber: ' 98765 22222 ',
              ),
            ),
          )
          ..add(const StaffContactEdited(1, ContactTexts(contactName: 'Mini', countryCode: '91')))
          ..add(const StaffContactPrimaryChosen(0, isPrimary: true))
          ..add(const StaffFormSubmitted(_texts, _place));
        await bloc.stream.firstWhere((state) => state is StaffFormSaved);
      },
      verify: (_) {
        final draft = verify(() => staff.create(any(), captureAny())).captured.single as StaffDraft;
        expect(draft.emergencyContacts, const [
          EmergencyContact(
            contactName: 'Anil',
            relation: 'Father',
            phone: Phone(countryCode: '91', number: '9876511111'),
            alternateNumber: '9876522222',
            isPrimary: true,
          ),
          EmergencyContact(
            contactName: 'Mini',
            phone: Phone(countryCode: '91', number: ''),
            isPrimary: false,
          ),
        ]);
      },
    );
  });

  group('editing', () {
    setUp(() => when(() => staff.member('f1')).thenAnswer((_) async => kavyaMember));

    blocTest<StaffFormBloc, StaffFormState>(
      'starts from the staff member, with their lists as rows that keep their place',
      build: edit,
      act: (bloc) => bloc.add(const StaffFormStarted()),
      verify: (bloc) {
        final state = ready(bloc);
        expect(state.existing, kavyaMember);
        expect([state.gender, state.bloodGroup, state.dateOfBirth], [Gender.female, 'O+', '1990-04-17']);
        expect(
          [state.joiningDate, state.resignationDate, state.employmentType],
          [
            '2020-06-01',
            '2026-03-31',
            EmploymentType.fullTime,
          ],
        );
        expect([state.categoryId, state.designationId], ['c1', 'd1']);
        // The photo is the record's own until another is uploaded.
        expect(state.photoFileId, isNull);
        expect(state.educations, [EducationEntry(0, EducationTexts.fromEducation(kavyaMember.educations.single))]);
        expect([for (final entry in state.contacts) entry.id], [1, 2]);
        expect([for (final entry in state.contacts) entry.isPrimary], [true, false]);
        expect(state.contacts.first.texts, ContactTexts.fromContact(kavyaMember.emergencyContacts.first));
        expect(state.nextRowId, 3);
      },
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'says the staff member is missing when they cannot be read',
      build: edit,
      setUp: () => when(
        () => staff.member('f1'),
      ).thenThrow(const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')),
      act: (bloc) => bloc.add(const StaffFormStarted()),
      expect: () => [
        const StaffFormLoading(),
        const StaffFormFailed(ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')),
      ],
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'sends the version it read and no email, and the lists as they stand',
      build: edit,
      setUp: () => when(() => staff.update(any(), any(), any())).thenAnswer((_) async => kavyaMember),
      act: (bloc) async {
        await started(bloc);
        bloc
          ..add(const StaffContactRemoved(2))
          ..add(const StaffDesignationChosen(null))
          ..add(
            const StaffFormSubmitted(
              StaffTexts(
                firstName: 'Kavya',
                lastName: 'Nair',
                email: 'ignored@example.com',
                mobileCountryCode: '91',
                mobileNumber: '9876543210',
              ),
              _place,
            ),
          );
        await bloc.stream.firstWhere((state) => state is StaffFormSaved);
      },
      verify: (_) {
        final draft = verify(() => staff.update('f1', 4, captureAny())).captured.single as StaffDraft;
        expect(draft.email, isEmpty);
        expect(draft.designationId, isNull);
        expect(draft.photoFileId, isNull);
        expect(draft.educations, kavyaMember.educations);
        expect(draft.emergencyContacts, [kavyaMember.emergencyContacts.first]);
        expect(draft.dateOfBirth, '1990-04-17');
      },
    );

    blocTest<StaffFormBloc, StaffFormState>(
      'keeps the failure for a version conflict, and reads the staff member again on Reload',
      build: edit,
      setUp: () => when(() => staff.update(any(), any(), any())).thenThrow(
        const ApiFailure(statusCode: 409, code: 'VERSION_CONFLICT', message: 'x'),
      ),
      act: (bloc) async {
        await started(bloc);
        bloc.add(const StaffFormSubmitted(_texts, _place));
        await bloc.stream.firstWhere((state) => state is StaffFormReady && state.failure != null);
        bloc.add(const StaffFormStarted());
      },
      verify: (_) => verify(() => staff.member('f1')).called(2),
      expect: () => anything,
    );
  });

  group('a save that is refused while the form was changed', () {
    const refusal = ApiFailure(
      statusCode: 400,
      code: 'VALIDATION_FAILED',
      message: 'x',
      fieldErrors: [FieldError(field: 'educations[0].degree', code: 'REQUIRED', message: 'Enter the degree')],
    );

    /// Opens Kavya's form, sends Save, and holds the save on its way; [change] runs while it is out, then it is refused.
    Future<StaffFormBloc> refusedAfter(void Function(StaffFormBloc bloc) change) async {
      final held = Completer<StaffMember>();
      when(() => staff.member('f1')).thenAnswer((_) async => kavyaMember);
      when(() => staff.update(any(), any(), any())).thenAnswer((_) => held.future);
      final bloc = edit();
      addTearDown(bloc.close);
      await started(bloc);
      bloc.add(const StaffFormSubmitted(_texts, _place));
      await bloc.stream.firstWhere((state) => state is StaffFormReady && state.saving);
      change(bloc);
      await pumpEventQueue();
      held.completeError(refusal);
      await bloc.stream.firstWhere((state) => state is StaffFormReady && !state.saving);
      return bloc;
    }

    test('keeps a line changed, a contact added and a choice made meanwhile, and the next Save sends them', () async {
      final bloc = await refusedAfter(
        (bloc) => bloc
          ..add(const StaffEducationEdited(0, EducationTexts(degree: 'M.Ed')))
          ..add(const StaffContactAdded())
          ..add(const StaffGenderChosen(Gender.other)),
      );
      final state = ready(bloc);
      expect(state.educations.single.texts.degree, 'M.Ed');
      expect(state.contacts, hasLength(3));
      expect(state.gender, Gender.other);
      expect(state.saving, isFalse);
      expect(state.failure, refusal);
      when(() => staff.update(any(), any(), any())).thenAnswer((_) async => kavyaMember);
      bloc.add(const StaffFormSubmitted(_texts, _place));
      await bloc.stream.firstWhere((state) => state is StaffFormSaved);
      final draft = verify(() => staff.update('f1', 4, captureAny())).captured.last as StaffDraft;
      expect(draft.educations.single.degree, 'M.Ed');
      expect(draft.emergencyContacts, hasLength(3));
      expect(draft.gender, Gender.other);
    });

    test('names the rows the save sent, so an error stays with its row when rows are added or removed', () async {
      final bloc = await refusedAfter(
        (bloc) => bloc
          ..add(const StaffContactRemoved(1))
          ..add(const StaffEducationAdded()),
      );
      final state = ready(bloc);
      expect(state.failedEducationIds, [0]);
      expect(state.failedContactIds, [1, 2]);
      expect(state.educations.map((e) => e.id), [0, 3]);
      expect(state.contacts.map((c) => c.id), [2]);
    });

    test('forgets the rows of the last refusal when Save is sent again', () async {
      final bloc = await refusedAfter((_) {});
      expect(ready(bloc).failedEducationIds, [0]);
      final held = Completer<StaffMember>();
      when(() => staff.update(any(), any(), any())).thenAnswer((_) => held.future);
      bloc.add(const StaffFormSubmitted(_texts, _place));
      await bloc.stream.firstWhere((state) => state is StaffFormReady && state.saving);
      expect(ready(bloc).failure, isNull);
      expect(ready(bloc).failedEducationIds, isEmpty);
      expect(ready(bloc).failedContactIds, isEmpty);
      held.complete(kavyaMember);
    });
  });
}
