import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:bravynix_school_erp/features/files/domain/uploaded_file.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/place_choice.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_form_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_form_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/files.dart';
import '../../helpers/institutions.dart';
import '../../helpers/leaving_a_form.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/staff.dart';

class _MockFormBloc extends MockBloc<StaffFormEvent, StaffFormState> implements StaffFormBloc;

const _lowerPrimary = MasterEntry(id: 'c1', name: 'Lower Primary');

const _addState = StaffFormReady(
  categories: [_lowerPrimary],
  designations: [designationEntry, otherDesignation],
  educations: [],
  contacts: [],
  nextRowId: 0,
);

/// Kavya as the bloc opens her: every field set, one education line (row 0), two contacts (rows 1 and 2).
final _editState = StaffFormReady(
  existing: kavyaMember,
  categories: const [_lowerPrimary],
  designations: const [designationEntry, otherDesignation],
  gender: Gender.female,
  bloodGroup: 'O+',
  dateOfBirth: '1990-04-17',
  joiningDate: '2020-06-01',
  resignationDate: '2026-03-31',
  employmentType: EmploymentType.fullTime,
  categoryId: 'c1',
  designationId: 'd1',
  educations: [EducationEntry(0, EducationTexts.fromEducation(kavyaMember.educations.single))],
  contacts: [
    ContactEntry(1, ContactTexts.fromContact(kavyaMember.emergencyContacts[0]), isPrimary: true),
    ContactEntry(2, ContactTexts.fromContact(kavyaMember.emergencyContacts[1])),
  ],
  nextRowId: 3,
);

ApiFailure _failure(int status, String code, {List<FieldError> fields = const []}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words', fieldErrors: fields);

/// An upload that waits to be released, and notes what it was asked for.
class _Gate implements FilesRepository {
  late Completer<void> release;
  final List<(FilePurpose, String)> asked = [];

  @override
  Future<UploadedFile> upload(
    ChosenFile file, {
    required FilePurpose purpose,
    required String institutionId,
    void Function(double sent)? onProgress,
    CancelToken? cancelToken,
  }) async {
    asked.add((purpose, institutionId));
    release = Completer<void>();
    await release.future;
    return uploadedPhoto;
  }
}

void main() {
  late _MockFormBloc bloc;
  late MockMastersRepository masters;
  late FakeFilePicking picking;
  late _Gate files;

  setUpAll(() {
    registerFallbackValue(const StaffFormStarted());
    registerFallbackValue(MasterType.countries);
  });

  setUp(() {
    bloc = _MockFormBloc();
    masters = MockMastersRepository();
    picking = FakeFilePicking(result: photo);
    files = _Gate();
    when(() => masters.entries(MasterType.countries)).thenAnswer((_) async => [india]);
    when(() => masters.entries(MasterType.states, parentId: 'k1')).thenAnswer((_) async => [karnataka, kerala]);
    when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) async => [bengaluru, mysuru]);
    // The form starts its own place picker and photo upload from these.
    getIt
      ..registerSingleton<MastersRepository>(masters)
      ..registerSingleton<FilesRepository>(files)
      ..registerSingleton<FilePicking>(picking);
  });
  tearDown(getIt.reset);

  Future<void> pump(
    WidgetTester tester,
    StaffFormState state, {
    String? staffId,
    double textScale = 1,
    Size size = const Size(400, 6000),
  }) async {
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.staffId).thenReturn(staffId);
    when(() => bloc.institutionId).thenReturn(staffId == null ? 'i7' : null);
    await tester.pumpAppScaled(
      BlocProvider<StaffFormBloc>.value(value: bloc, child: const StaffFormView()),
      textScale: textScale,
      size: size,
    );
    // The place lists are read as the form opens.
    await tester.pump();
  }

  Finder field(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));
  String textOf(WidgetTester tester, String key) => tester.widget<TextField>(field(key)).controller!.text;
  Finder saveButton() => find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(FilledButton));

  StaffFormSubmitted submitted() =>
      verify(() => bloc.add(captureAny(that: isA<StaffFormSubmitted>()))).captured.single as StaffFormSubmitted;

  group('adding', () {
    testWidgets('an empty form: the dial code starts as India, the email is typed, and the lists are offered', (
      tester,
    ) async {
      await pump(tester, _addState);
      expect(find.text('Add staff'), findsOneWidget);
      expect(textOf(tester, 'staffForm.firstName'), isEmpty);
      expect(textOf(tester, 'staffForm.mobileCode'), '91');
      expect(tester.widget<TextField>(field('staffForm.email')).enabled, isTrue);
      expect(find.text('They sign in with a code sent to this email.'), findsOneWidget);
      expect(find.text('India'), findsOneWidget);
      expect(find.text('Choose a date'), findsNWidgets(3));
      expect(find.byKey(const Key('staffForm.photoKept')), findsNothing);
      expect(find.text('Education 1'), findsNothing);
    });

    testWidgets('sends what was typed, and the place, when Save is pressed', (tester) async {
      await pump(tester, _addState);
      await tester.enterText(field('staffForm.firstName'), 'Ravi');
      await tester.enterText(field('staffForm.lastName'), 'Shetty');
      await tester.enterText(field('staffForm.email'), 'ravi@example.com');
      await tester.enterText(field('staffForm.mobileNumber'), '9876543210');
      await tester.enterText(field('staffForm.alternate'), '9876500000');
      await tester.enterText(field('staffForm.nationality'), 'Indian');
      await tester.enterText(field('staffForm.employeeCode'), 'T-020');
      await tester.enterText(field('staffForm.line1'), '3 Hill Street');
      await tester.enterText(field('staffForm.line2'), 'Near the park');
      await tester.enterText(field('staffForm.pincode'), '560066');
      await tester.tap(find.text('Save'));
      final sent = submitted();
      expect(sent.place, const PlaceChoice(countryId: 'k1'));
      expect(
        sent.texts,
        const StaffTexts(
          firstName: 'Ravi',
          lastName: 'Shetty',
          email: 'ravi@example.com',
          mobileCountryCode: '91',
          mobileNumber: '9876543210',
          alternateNumber: '9876500000',
          nationality: 'Indian',
          employeeCode: 'T-020',
          addressLine1: '3 Hill Street',
          addressLine2: 'Near the park',
          pincode: '560066',
        ),
      );
    });

    testWidgets('Save waits until the place is read', (tester) async {
      final lists = Completer<List<MasterEntry>>();
      when(() => masters.entries(MasterType.countries)).thenAnswer((_) => lists.future);
      await pump(tester, _addState);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);
      lists.complete([india]);
      await tester.pump();
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
    });

    testWidgets('says why the place could not be read, and reads it again on Try again', (tester) async {
      var calls = 0;
      when(() => masters.entries(MasterType.countries)).thenAnswer((_) async {
        if (++calls == 1) throw const ApiFailure.network();
        return [india];
      });
      await pump(tester, _addState);
      expect(find.byKey(const Key('staffForm.placeFailed')), findsOneWidget);
      await tester.tap(find.byKey(const Key('staffForm.placeRetry')));
      await tester.pump();
      expect(find.byKey(const Key('staffForm.placeFailed')), findsNothing);
      expect(find.text('India'), findsOneWidget);
    });
  });

  group('the photo', () {
    Future<void> chooseFromGallery(WidgetTester tester) async {
      await tester.tap(find.text('Add photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('photo.gallery')));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('Save waits while the photo is on its way, and the ID reaches the bloc once it is checked', (
      tester,
    ) async {
      await pump(tester, _addState);
      await chooseFromGallery(tester);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);
      verifyNever(() => bloc.add(any(that: isA<StaffPhotoChosen>())));
      files.release.complete();
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffPhotoChosen('f1'))).called(1);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
    });

    testWidgets('says a saved photo is kept until another is chosen, for an edit that has one', (tester) async {
      await pump(tester, _editState, staffId: 'f1');
      expect(find.byKey(const Key('staffForm.photoKept')), findsOneWidget);
      expect(find.text('A photo is saved. Choose another to replace it.'), findsOneWidget);
    });

    testWidgets('says nothing of a saved photo once another is chosen, or when the record has none', (tester) async {
      await pump(tester, _editState.copyWith(photoFileId: () => 'f9'), staffId: 'f1');
      expect(find.byKey(const Key('staffForm.photoKept')), findsNothing);
    });

    testWidgets('is sent as a staff photo for the Institution a new staff member is added to', (tester) async {
      await pump(tester, _addState);
      await chooseFromGallery(tester);
      expect(files.asked, [(FilePurpose.staffPhoto, 'i7')]);
    });

    testWidgets('is sent for the Institution the edited staff member is based at', (tester) async {
      await pump(tester, _editState, staffId: 'f1');
      await chooseFromGallery(tester);
      expect(files.asked, [(FilePurpose.staffPhoto, kavyaMember.homeInstitutionId)]);
    });
  });

  group('editing', () {
    testWidgets('starts from the staff member, the login cannot be changed here', (tester) async {
      await pump(tester, _editState, staffId: 'f1');
      expect(find.text('Edit staff'), findsOneWidget);
      expect(textOf(tester, 'staffForm.firstName'), 'Kavya');
      expect(textOf(tester, 'staffForm.lastName'), 'Nair');
      expect(textOf(tester, 'staffForm.email'), 'kavya.nair@example.com');
      expect(tester.widget<TextField>(field('staffForm.email')).enabled, isFalse);
      expect(find.text("The login email can't be changed here."), findsOneWidget);
      expect(textOf(tester, 'staffForm.mobileCode'), '91');
      expect(textOf(tester, 'staffForm.mobileNumber'), '9876543210');
      expect(textOf(tester, 'staffForm.alternate'), '9876500000');
      expect(textOf(tester, 'staffForm.nationality'), 'Indian');
      expect(textOf(tester, 'staffForm.employeeCode'), 'T-014');
      expect(textOf(tester, 'staffForm.line1'), '12 Lake Road');
      expect(textOf(tester, 'staffForm.line2'), 'Near the park');
      expect(textOf(tester, 'staffForm.pincode'), '560066');
      for (final text in [
        'Female',
        'O+',
        '17-04-1990',
        'Karnataka',
        'Bengaluru',
        'Lower Primary',
        'Mathematics Teacher',
        'Full time',
        '01-06-2020',
        '31-03-2026',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('shows the education line and the contacts the record holds, the primary one marked', (tester) async {
      await pump(tester, _editState, staffId: 'f1');
      expect(find.text('Education 1'), findsOneWidget);
      expect(textOf(tester, 'staffForm.education.0.degree'), 'B.Ed');
      expect(textOf(tester, 'staffForm.education.0.qualification'), 'Education');
      expect(textOf(tester, 'staffForm.education.0.specialization'), 'Mathematics');
      expect(textOf(tester, 'staffForm.education.0.institutionName'), 'Mysore University');
      expect(textOf(tester, 'staffForm.education.0.yearOfPassing'), '2014');
      expect(find.text('Contact 1'), findsOneWidget);
      expect(find.text('Contact 2'), findsOneWidget);
      expect(textOf(tester, 'staffForm.contact.1.name'), 'Anil Nair');
      expect(textOf(tester, 'staffForm.contact.1.relation'), 'Father');
      expect(textOf(tester, 'staffForm.contact.1.code'), '91');
      expect(textOf(tester, 'staffForm.contact.1.number'), '9876511111');
      expect(textOf(tester, 'staffForm.contact.1.alternate'), '9876522222');
      expect(textOf(tester, 'staffForm.contact.2.name'), 'Mini Nair');
      final primary = find.descendant(
        of: find.byKey(const Key('staffForm.contact.1.primary')),
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(primary).value, isTrue);
    });

    testWidgets('sends the place it holds with the texts, unless it was changed', (tester) async {
      await pump(tester, _editState, staffId: 'f1');
      await tester.tap(find.text('Save'));
      expect(submitted().place, const PlaceChoice(countryId: 'k1', stateId: 's1', cityId: 'y1'));
    });

    testWidgets('sends the place chosen in the address', (tester) async {
      await pump(tester, _editState, staffId: 'f1');
      await tester.tap(find.byKey(const Key('staffForm.city')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mysuru').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      expect(submitted().place, const PlaceChoice(countryId: 'k1', stateId: 's1', cityId: 'y2'));
    });
  });

  group('choosing', () {
    Future<void> choose(WidgetTester tester, String fieldKey, String option) async {
      await tester.tap(find.byKey(Key(fieldKey)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    testWidgets('tells the bloc what is chosen from each list', (tester) async {
      await pump(tester, _addState);
      await choose(tester, 'staffForm.gender', 'Male');
      verify(() => bloc.add(const StaffGenderChosen(Gender.male))).called(1);
      await choose(tester, 'staffForm.bloodGroup', 'AB+');
      verify(() => bloc.add(const StaffBloodGroupChosen('AB+'))).called(1);
      await choose(tester, 'staffForm.category', 'Lower Primary');
      verify(() => bloc.add(const StaffCategoryChosen('c1'))).called(1);
      await choose(tester, 'staffForm.designation', 'Principal');
      verify(() => bloc.add(const StaffDesignationChosen('d2'))).called(1);
      await choose(tester, 'staffForm.employmentType', 'Contract');
      verify(() => bloc.add(const StaffEmploymentTypeChosen(EmploymentType.contract))).called(1);
    });

    testWidgets('lets a list that may be empty be cleared, but not the category', (tester) async {
      await pump(tester, _editState, staffId: 'f1');
      await choose(tester, 'staffForm.designation', 'Not set');
      verify(() => bloc.add(const StaffDesignationChosen(null))).called(1);
      List<DropdownMenuItem<String?>> itemsOf(String key) => tester
          .widget<DropdownButton<String?>>(
            find.descendant(of: find.byKey(Key(key)), matching: find.byType(DropdownButton<String?>)),
          )
          .items!;
      expect(itemsOf('staffForm.designation'), hasLength(3));
      expect(itemsOf('staffForm.category'), hasLength(1));
    });

    testWidgets('keeps a category or designation that is hidden now, shown as empty', (tester) async {
      await pump(
        tester,
        const StaffFormReady(
          existing: kavyaMember,
          categories: [],
          designations: [],
          categoryId: 'c1',
          designationId: 'd1',
          educations: [],
          contacts: [],
          nextRowId: 0,
        ),
        staffId: 'f1',
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Mathematics Teacher'), findsNothing);
    });

    testWidgets('opens the calendar on the day set, and tells the bloc the day picked', (tester) async {
      await pump(tester, _editState, staffId: 'f1');
      await tester.tap(find.byKey(const Key('staffForm.dateOfBirth')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffBirthDateChosen('1990-04-17'))).called(1);
    });

    testWidgets('opens the calendar for a date of birth thirty years back when none is set', (tester) async {
      await pump(tester, _addState);
      await tester.tap(find.byKey(const Key('staffForm.dateOfBirth')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final day =
          verify(() => bloc.add(captureAny(that: isA<StaffBirthDateChosen>()))).captured.single as StaffBirthDateChosen;
      expect(day.day, '${DateTime.now().year - 30}-01-01');
    });

    testWidgets('tells the bloc the joining and resignation days picked', (tester) async {
      await pump(tester, _editState, staffId: 'f1');
      await tester.tap(find.byKey(const Key('staffForm.joiningDate')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffJoiningDateChosen('2020-06-01'))).called(1);
      await tester.tap(find.byKey(const Key('staffForm.resignationDate')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffResignationDateChosen('2026-03-31'))).called(1);
    });

    testWidgets('clears a day that was set, and offers no clear button for one that is not', (tester) async {
      await pump(tester, _editState.copyWith(joiningDate: () => null), staffId: 'f1');
      expect(find.byTooltip('Clear Joining date'), findsNothing);
      await tester.tap(find.byTooltip('Clear Date of birth'));
      verify(() => bloc.add(const StaffBirthDateChosen(null))).called(1);
    });
  });

  group('the lists', () {
    testWidgets('adds a line and a contact', (tester) async {
      await pump(tester, _addState);
      await tester.tap(find.byKey(const Key('staffForm.addEducation')));
      verify(() => bloc.add(const StaffEducationAdded())).called(1);
      await tester.tap(find.byKey(const Key('staffForm.addContact')));
      verify(() => bloc.add(const StaffContactAdded())).called(1);
    });

    testWidgets('tells the bloc what is typed in a line, with the year as digits only', (tester) async {
      await pump(tester, _editState, staffId: 'f1');
      await tester.enterText(field('staffForm.education.0.degree'), 'M.Ed');
      verify(
        () => bloc.add(
          const StaffEducationEdited(
            0,
            EducationTexts(
              degree: 'M.Ed',
              qualification: 'Education',
              specialization: 'Mathematics',
              institutionName: 'Mysore University',
              yearOfPassing: '2014',
            ),
          ),
        ),
      ).called(1);
      await tester.enterText(field('staffForm.education.0.yearOfPassing'), '2a0b1c');
      expect(textOf(tester, 'staffForm.education.0.yearOfPassing'), '201');
    });

    testWidgets('removes a line', (tester) async {
      await pump(tester, _editState, staffId: 'f1');
      await tester.tap(find.byKey(const Key('staffForm.education.0.remove')));
      verify(() => bloc.add(const StaffEducationRemoved(0))).called(1);
      expect(find.text('Remove education 1'), findsOneWidget);
    });

    testWidgets('tells the bloc what is typed in a contact', (tester) async {
      await pump(tester, _editState, staffId: 'f1');
      await tester.enterText(field('staffForm.contact.2.number'), '9876544444');
      verify(
        () => bloc.add(
          const StaffContactEdited(
            2,
            ContactTexts(
              contactName: 'Mini Nair',
              countryCode: '91',
              number: '9876544444',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('makes a contact the primary, and removes one', (tester) async {
      await pump(tester, _editState, staffId: 'f1');
      await tester.tap(find.byKey(const Key('staffForm.contact.2.primary')));
      verify(() => bloc.add(const StaffContactPrimaryChosen(2, isPrimary: true))).called(1);
      await tester.tap(find.byKey(const Key('staffForm.contact.2.remove')));
      verify(() => bloc.add(const StaffContactRemoved(2))).called(1);
    });

    testWidgets('offers no more lines at 20, and no more contacts at 10', (tester) async {
      await pump(
        tester,
        StaffFormReady(
          categories: const [],
          designations: const [],
          educations: [for (var i = 0; i < maxEducations; i++) EducationEntry(i, const EducationTexts())],
          contacts: [
            for (var i = 0; i < maxEmergencyContacts; i++) ContactEntry(maxEducations + i, const ContactTexts()),
          ],
          nextRowId: maxEducations + maxEmergencyContacts,
        ),
        size: const Size(400, 40000),
      );
      expect(tester.widget<AppButton>(find.byKey(const Key('staffForm.addEducation'))).onPressed, isNull);
      expect(tester.widget<AppButton>(find.byKey(const Key('staffForm.addContact'))).onPressed, isNull);
    });
  });

  group('after a refused save', () {
    StaffFormReady refused(ApiFailure failure, {StaffFormReady? from}) =>
        (from ?? _editState).copyWith(failure: () => failure);

    testWidgets('shows each field error under its field, and under the row it names', (tester) async {
      await pump(
        tester,
        refused(
          _failure(
            400,
            'VALIDATION_FAILED',
            fields: const [
              FieldError(field: 'firstName', code: 'REQUIRED', message: 'Enter the first name'),
              FieldError(field: 'mobile.number', code: 'INVALID_FORMAT', message: 'Not a phone number'),
              FieldError(field: 'classCategoryId', code: 'REQUIRED', message: 'Choose a category'),
              FieldError(field: 'resignationDate', code: 'INVALID_VALUE', message: 'Before the joining date'),
              FieldError(field: 'address.stateId', code: 'INVALID_VALUE', message: 'Not a state of India'),
              FieldError(field: 'educations[0].degree', code: 'REQUIRED', message: 'Enter the degree'),
              FieldError(
                field: 'emergencyContacts[1].phone.number',
                code: 'INVALID_FORMAT',
                message: 'Bad contact number',
              ),
              FieldError(field: 'emergencyContacts[0].isPrimary', code: 'INVALID_VALUE', message: 'Only one primary'),
            ],
          ),
        ),
        staffId: 'f1',
      );
      for (final text in [
        'Enter the first name',
        'Not a phone number',
        'Choose a category',
        'Before the joining date',
        'Not a state of India',
        'Enter the degree',
        'Bad contact number',
        'Only one primary',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.byKey(const Key('staffForm.error')), findsNothing);
    });

    testWidgets('says an Employee ID in use under the field when the API names it', (tester) async {
      await pump(
        tester,
        refused(
          _failure(
            409,
            'EMPLOYEE_ID_TAKEN',
            fields: const [
              FieldError(field: 'employeeCode', code: 'EMPLOYEE_ID_TAKEN', message: 'Taken here'),
            ],
          ),
        ),
        staffId: 'f1',
      );
      expect(find.text('Taken here'), findsOneWidget);
      expect(find.byKey(const Key('staffForm.error')), findsNothing);
    });

    for (final (status, code, text) in [
      (409, 'EMPLOYEE_ID_TAKEN', 'Another staff member of this Institution has this Employee ID.'),
      (409, 'DUPLICATE', 'This person already has a staff record in this Society.'),
      (409, 'ROLE_CONFLICT', "This email belongs to a platform account, which can't also be staff."),
      (409, 'ACCOUNT_BLOCKED', "This account is blocked and can't access the app."),
      (409, 'VERSION_CONFLICT', 'Someone else changed this. Your changes were not saved.'),
      (422, 'REFERENCE_INACTIVE', 'Something you chose is no longer available. Choose again.'),
      (403, 'FORBIDDEN', "You don't have access to this."),
      (404, 'NOT_FOUND', 'This staff member could not be found. They may have been deactivated.'),
    ]) {
      testWidgets('says $code in words above the form', (tester) async {
        await pump(tester, refused(_failure(status, code)), staffId: 'f1');
        expect(find.byKey(const Key('staffForm.error')), findsOneWidget);
        expect(find.text(text), findsOneWidget);
      });
    }

    testWidgets('says an error on a row that is not there above the form, not nowhere', (tester) async {
      await pump(
        tester,
        refused(
          _failure(
            400,
            'VALIDATION_FAILED',
            fields: const [
              FieldError(field: 'educations[4].degree', code: 'REQUIRED', message: 'Enter the degree'),
            ],
          ),
        ),
        staffId: 'f1',
      );
      expect(find.byKey(const Key('staffForm.error')), findsOneWidget);
    });

    testWidgets('offers Reload after a version conflict, which reads the staff member again', (tester) async {
      await pump(tester, refused(_failure(409, 'VERSION_CONFLICT')), staffId: 'f1');
      await tester.tap(find.byKey(const Key('staffForm.reload')));
      verify(() => bloc.add(const StaffFormStarted())).called(1);
    });

    testWidgets('offers Reload for no other failure', (tester) async {
      await pump(tester, refused(const ApiFailure.network()), staffId: 'f1');
      expect(find.byKey(const Key('staffForm.reload')), findsNothing);
      expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
    });

    leavingAFormTests(
      closing: const [(404, 'NOT_FOUND')],
      staying: const [(409, 'VERSION_CONFLICT'), (409, 'DUPLICATE')],
      setFailure: (failure) {
        when(() => bloc.staffId).thenReturn(null);
        when(() => bloc.institutionId).thenReturn('i7');
        when(() => bloc.state).thenReturn(failure == null ? _addState : _addState.copyWith(failure: () => failure));
      },
      form: () => BlocProvider<StaffFormBloc>.value(value: bloc, child: const StaffFormView()),
    );
  });

  group('before the form is ready', () {
    testWidgets('shows a placeholder while it loads', (tester) async {
      await pump(tester, const StaffFormLoading());
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('says why it could not be read, and starts again on Try again', (tester) async {
      await pump(tester, const StaffFormFailed(ApiFailure.network()));
      expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const StaffFormStarted())).called(1);
    });

    testWidgets('says there is no access, with no retry', (tester) async {
      await pump(tester, StaffFormFailed(_failure(403, 'FORBIDDEN')));
      expect(find.byKey(const Key('staffForm.forbidden')), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('says the staff member is gone, with no retry', (tester) async {
      await pump(tester, StaffFormFailed(_failure(404, 'NOT_FOUND')), staffId: 'f1');
      expect(find.text('This staff member could not be found. They may have been deactivated.'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });
  });

  testWidgets('closes with a message and tells the screen behind it once saved', (tester) async {
    whenListen(bloc, Stream.value(const StaffFormSaved(kavyaMember)), initialState: _addState);
    when(() => bloc.staffId).thenReturn(null);
    when(() => bloc.institutionId).thenReturn('i7');
    bool? result;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await context.push<bool>('/form'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/form',
          builder: (_, _) => BlocProvider<StaffFormBloc>.value(value: bloc, child: const StaffFormView()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.text('Staff saved'), findsOneWidget);
  });

  testWidgets('does not send twice while saving', (tester) async {
    await pump(tester, _addState.copyWith(saving: true));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(saveButton());
    verifyNever(() => bloc.add(any(that: isA<StaffFormSubmitted>())));
  });

  testWidgets('reads whole at a large text scale on a small phone, with its lists', (tester) async {
    await pump(tester, _editState, staffId: 'f1', textScale: 2, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
    await tester.scrollUntilVisible(
      find.byKey(const Key('staffForm.addContact')),
      300,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
