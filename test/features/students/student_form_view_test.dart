import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:bravynix_school_erp/features/files/domain/uploaded_file.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/place_choice.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/student_draft.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_form_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_form_page.dart';
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
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/students.dart';

class _MockFormBloc extends MockBloc<StudentFormEvent, StudentFormState> implements StudentFormBloc;

/// An upload that waits to be released, and notes what it was asked for.
class _Gate extends Fake implements FilesRepository {
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

/// The form as it opens: one empty guardian, nothing chosen.
const _empty = StudentFormReady(
  options: studentOptions,
  guardians: [GuardianEntry(0, GuardianTexts(), isPrimary: true)],
  nextRowId: 1,
);

/// Two guardians (rows 0 and 3), the first primary, a class and its section chosen.
const _filled = StudentFormReady(
  options: studentOptions,
  yearId: 'y1',
  classId: 'c1',
  sectionId: 'e1',
  guardians: [
    GuardianEntry(0, GuardianTexts(firstName: 'Ravi', number: '9845012345'), isPrimary: true),
    GuardianEntry(3, GuardianTexts(firstName: 'Sita', number: '9845054321')),
  ],
  nextRowId: 4,
);

ApiFailure _failure(int status, String code, {List<FieldError> fields = const []}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words', fieldErrors: fields);

void main() {
  late _MockFormBloc bloc;
  late MockMastersRepository masters;
  late _Gate files;

  setUpAll(() {
    registerFallbackValue(const StudentFormStarted());
    registerFallbackValue(MasterType.countries);
  });

  setUp(() {
    bloc = _MockFormBloc();
    masters = MockMastersRepository();
    files = _Gate();
    when(() => masters.entries(MasterType.countries)).thenAnswer((_) async => [india]);
    when(() => masters.entries(MasterType.states, parentId: 'k1')).thenAnswer((_) async => [karnataka, kerala]);
    when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) async => [bengaluru, mysuru]);
    when(() => bloc.institutionId).thenReturn('i1');
    // The form starts its own place picker and photo upload from these.
    getIt
      ..registerSingleton<MastersRepository>(masters)
      ..registerSingleton<FilesRepository>(files)
      ..registerSingleton<FilePicking>(FakeFilePicking(result: photo));
  });
  tearDown(getIt.reset);

  Future<void> pump(
    WidgetTester tester,
    StudentFormState state, {
    double textScale = 1,
    Size size = const Size(400, 8000),
  }) async {
    when(() => bloc.state).thenReturn(state);
    await tester.pumpAppScaled(
      BlocProvider<StudentFormBloc>.value(value: bloc, child: const StudentFormView()),
      textScale: textScale,
      size: size,
    );
    // The place lists are read as the form opens.
    await tester.pump();
  }

  Finder field(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));
  Finder saveButton() => find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(FilledButton));

  StudentFormSubmitted submitted() =>
      verify(() => bloc.add(captureAny(that: isA<StudentFormSubmitted>()))).captured.single as StudentFormSubmitted;

  Future<void> choose(WidgetTester tester, String fieldKey, String option) async {
    await tester.tap(find.byKey(Key(fieldKey)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  group('adding', () {
    testWidgets('an empty form: the dial code starts as India and one guardian is offered', (tester) async {
      await pump(tester, _empty);
      expect(find.text('Add student'), findsOneWidget);
      expect(find.text('Guardian 1'), findsOneWidget);
      expect(find.text('Guardian 2'), findsNothing);
      expect(tester.widget<TextField>(field('studentForm.mobileCode')).controller!.text, '91');
      expect(find.text('India'), findsOneWidget);
      // The only guardian cannot be removed.
      expect(find.byKey(const Key('studentForm.guardian.0.remove')), findsNothing);
    });

    testWidgets('sends what was typed, and the place, when Save is pressed', (tester) async {
      await pump(tester, _filled);
      await tester.enterText(field('studentForm.firstName'), 'Asha');
      await tester.enterText(field('studentForm.lastName'), 'Rao');
      await tester.enterText(field('studentForm.admissionNo'), 'A-2026-014');
      await tester.enterText(field('studentForm.contactEmail'), 'asha@example.com');
      await tester.enterText(field('studentForm.mobileNumber'), '9876543210');
      await tester.enterText(field('studentForm.alternate'), '9876500000');
      await tester.enterText(field('studentForm.nationality'), 'Indian');
      await tester.enterText(field('studentForm.line1'), '3 Hill Street');
      await tester.enterText(field('studentForm.line2'), 'Near the park');
      await tester.enterText(field('studentForm.pincode'), '560066');
      await tester.enterText(field('studentForm.rollNumber'), '14');
      await tester.enterText(field('studentForm.aadhaar'), '1234 5678 9012');
      await tester.enterText(field('studentForm.birthCertificate'), 'BC-77');
      await tester.tap(find.text('Save'));
      final sent = submitted();
      expect(sent.place, const PlaceChoice(countryId: 'k1'));
      expect(
        sent.texts,
        const StudentTexts(
          firstName: 'Asha',
          lastName: 'Rao',
          admissionNo: 'A-2026-014',
          contactEmail: 'asha@example.com',
          mobileCountryCode: '91',
          mobileNumber: '9876543210',
          alternateNumber: '9876500000',
          nationality: 'Indian',
          addressLine1: '3 Hill Street',
          addressLine2: 'Near the park',
          pincode: '560066',
          rollNumber: '14',
          aadhaar: '1234 5678 9012',
          birthCertificate: 'BC-77',
        ),
      );
    });

    testWidgets('keeps the Aadhaar field to digits, spaces and hyphens, and to twelve digits with their separators', (
      tester,
    ) async {
      await pump(tester, _filled);
      await tester.enterText(field('studentForm.aadhaar'), 'ab12-34 5678 9012 345');
      expect(tester.widget<TextField>(field('studentForm.aadhaar')).controller!.text, '12-34 5678 901');
    });

    testWidgets('Save waits until the place is read', (tester) async {
      final lists = Completer<List<MasterEntry>>();
      when(() => masters.entries(MasterType.countries)).thenAnswer((_) => lists.future);
      await pump(tester, _filled);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);
      lists.complete([india]);
      await tester.pump();
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
    });

    testWidgets('does not send twice while saving', (tester) async {
      await pump(tester, _filled.copyWith(saving: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(saveButton());
      verifyNever(() => bloc.add(any(that: isA<StudentFormSubmitted>())));
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

    testWidgets('is sent for the Institution, Save waits while it is on its way, and the ID reaches the bloc', (
      tester,
    ) async {
      await pump(tester, _filled);
      await chooseFromGallery(tester);
      expect(files.asked, [(FilePurpose.studentPhoto, 'i1')]);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);
      expect(find.text('Wait for the photo to finish sending.'), findsOneWidget);
      verifyNever(() => bloc.add(any(that: isA<StudentPhotoChosen>())));
      files.release.complete();
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StudentPhotoChosen('f1'))).called(1);
      expect(find.byKey(const Key('studentForm.uploadingWait')), findsNothing);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
    });
  });

  group('choosing', () {
    testWidgets('tells the bloc what is chosen from each list', (tester) async {
      await pump(tester, _empty);
      await choose(tester, 'studentForm.gender', 'Female');
      verify(() => bloc.add(const StudentGenderChosen(Gender.female))).called(1);
      await choose(tester, 'studentForm.bloodGroup', 'AB+');
      verify(() => bloc.add(const StudentBloodGroupChosen('AB+'))).called(1);
      await choose(tester, 'studentForm.year', '2026-2027');
      verify(() => bloc.add(const StudentYearChosen('y1'))).called(1);
      await choose(tester, 'studentForm.class', 'Class 2');
      verify(() => bloc.add(const StudentClassChosen('c2'))).called(1);
    });

    testWidgets('cannot choose a section until there is a class', (tester) async {
      await pump(tester, _empty);
      final section = find.descendant(
        of: find.byKey(const Key('studentForm.section')),
        matching: find.byType(DropdownButtonFormField<String?>),
      );
      expect(tester.widget<DropdownButtonFormField<String?>>(section).onChanged, isNull);
    });

    testWidgets('offers the sections of the class chosen', (tester) async {
      await pump(tester, _filled);
      await tester.tap(find.byKey(const Key('studentForm.section')));
      await tester.pumpAndSettle();
      expect(find.text('Class 1 · Blue'), findsOneWidget);
      expect(find.text('Class 2 · Section A'), findsNothing);
      await tester.tap(find.text('Class 1 · Blue'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StudentSectionChosen('e2'))).called(1);
    });

    testWidgets('tells the bloc the dates that are chosen', (tester) async {
      await pump(tester, _empty);
      await tester.tap(find.byKey(const Key('studentForm.admissionDate')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(any(that: isA<StudentAdmissionDateChosen>()))).called(1);
    });
  });

  group('guardians', () {
    testWidgets('shows a row for each, with the primary one marked and its own switch off', (tester) async {
      await pump(tester, _filled);
      expect(find.text('Guardian 1'), findsOneWidget);
      expect(find.text('Guardian 2'), findsOneWidget);
      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: find.byKey(const Key('studentForm.guardian.0.primary')),
                matching: find.byType(Switch),
              ),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: find.byKey(const Key('studentForm.guardian.0.primary')),
                matching: find.byType(Switch),
              ),
            )
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: find.byKey(const Key('studentForm.guardian.3.primary')),
                matching: find.byType(Switch),
              ),
            )
            .value,
        isFalse,
      );
    });

    testWidgets('adds a guardian', (tester) async {
      await pump(tester, _filled);
      await tester.tap(find.byKey(const Key('studentForm.addGuardian')));
      verify(() => bloc.add(const StudentGuardianAdded())).called(1);
    });

    testWidgets('offers no more once there are five', (tester) async {
      await pump(
        tester,
        _filled.copyWith(
          guardians: [
            for (var i = 0; i < maxGuardians; i++) GuardianEntry(i, const GuardianTexts(), isPrimary: i == 0),
          ],
        ),
      );
      final add = tester.widget<OutlinedButton>(
        find.descendant(of: find.byKey(const Key('studentForm.addGuardian')), matching: find.byType(OutlinedButton)),
      );
      expect(add.onPressed, isNull);
    });

    testWidgets('tells the bloc what is typed into a row, by its number', (tester) async {
      await pump(tester, _filled);
      await tester.enterText(field('studentForm.guardian.3.email'), 'sita@example.com');
      final edited =
          verify(() => bloc.add(captureAny(that: isA<StudentGuardianEdited>()))).captured.last as StudentGuardianEdited;
      expect(edited.id, 3);
      expect(edited.texts, const GuardianTexts(firstName: 'Sita', number: '9845054321', email: 'sita@example.com'));
    });

    testWidgets('removes a row, makes another primary, marks an emergency contact and chooses a relation', (
      tester,
    ) async {
      await pump(tester, _filled);
      await tester.tap(find.byKey(const Key('studentForm.guardian.3.remove')));
      verify(() => bloc.add(const StudentGuardianRemoved(3))).called(1);
      await tester.tap(find.byKey(const Key('studentForm.guardian.3.primary')));
      verify(() => bloc.add(const StudentGuardianPrimaryChosen(3))).called(1);
      await tester.tap(find.byKey(const Key('studentForm.guardian.3.emergency')));
      verify(() => bloc.add(const StudentGuardianEmergencyChosen(3, isEmergencyContact: true))).called(1);
      await choose(tester, 'studentForm.guardian.0.relation', 'Mother');
      verify(() => bloc.add(const StudentGuardianRelationChosen(0, GuardianRelation.mother))).called(1);
    });
  });

  group('guardian rows', () {
    testWidgets('are named by their place on the screen, and each title is a header for a screen reader', (
      tester,
    ) async {
      await pump(tester, _filled);
      // Rows 0 and 3 are the first and the second guardian.
      expect(find.text('Remove guardian 1'), findsOneWidget);
      expect(find.text('Remove guardian 2'), findsOneWidget);
      for (final title in ['Guardian 1', 'Guardian 2']) {
        expect(tester.getSemantics(find.text(title)), isSemantics(isHeader: true));
      }
    });
  });

  group('refused', () {
    StudentFormReady refused(ApiFailure failure, {List<int> rows = const [0, 3]}) =>
        _filled.copyWith(failure: () => failure, failedGuardianIds: rows);

    testWidgets('shows an error under the field the API names, and no banner', (tester) async {
      await pump(
        tester,
        refused(
          _failure(
            409,
            'ROLL_NUMBER_TAKEN',
            fields: const [FieldError(field: 'enrolment.rollNumber', code: 'ROLL_NUMBER_TAKEN', message: 'Roll taken')],
          ),
        ),
      );
      expect(find.text('Roll taken'), findsOneWidget);
      expect(find.byKey(const Key('studentForm.error')), findsNothing);
    });

    testWidgets('shows an error of a guardian under the row the save sent it as, not the row now in its place', (
      tester,
    ) async {
      // The save sent rows 0 and 3 in that order; the API's guardians[1] is row 3.
      await pump(
        tester,
        refused(
          _failure(
            400,
            'VALIDATION_FAILED',
            fields: const [FieldError(field: 'guardians[1].firstName', code: 'TOO_SHORT', message: 'Name needed')],
          ),
        ),
      );
      expect(
        find.descendant(of: find.byKey(const Key('studentForm.guardian.3')), matching: find.text('Name needed')),
        findsOneWidget,
      );
      expect(find.text('Name needed'), findsOneWidget);
      expect(find.byKey(const Key('studentForm.error')), findsNothing);
    });

    testWidgets('does not show an error under a row the save did not send', (tester) async {
      await pump(
        tester,
        refused(
          _failure(
            400,
            'VALIDATION_FAILED',
            fields: const [FieldError(field: 'guardians[0].firstName', code: 'TOO_SHORT', message: 'Name needed')],
          ),
          rows: [7],
        ),
      );
      expect(find.text('Name needed'), findsNothing);
    });

    testWidgets('says an empty required field is required, in the app’s words, under each field', (tester) async {
      await pump(
        tester,
        refused(
          const ApiFailure.invalid([
            FieldError.required('firstName'),
            FieldError.required('mobile.number'),
            FieldError.required('enrolment.classId'),
            FieldError.required('enrolment.sectionId'),
            FieldError.required('enrolment.rollNumber'),
            FieldError.required('guardians[0].relation'),
            FieldError.required('guardians[1].phone.number'),
          ]),
        ),
      );
      expect(find.text('This field is required.'), findsNWidgets(7));
      expect(find.byKey(const Key('studentForm.error')), findsNothing);
    });

    testWidgets('says an Aadhaar number that cannot be one under its field', (tester) async {
      await pump(
        tester,
        refused(
          const ApiFailure.invalid([FieldError(field: 'identity.aadhaarNumber', code: 'INVALID_AADHAAR', message: '')]),
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('studentForm.aadhaar')),
          matching: find.text('This is not a valid Aadhaar number. Check the twelve digits.'),
        ),
        findsOneWidget,
      );
    });

    for (final (field, key) in [
      ('enrolment.classId', 'studentForm.class'),
      ('identity.aadhaarNumber', 'studentForm.aadhaar'),
      ('guardians[0].phone', 'studentForm.guardian.0.mobileNumber'),
      ('guardians[0].email', 'studentForm.guardian.0.email'),
    ]) {
      testWidgets('shows the error the API names on $field under its field', (tester) async {
        await pump(
          tester,
          refused(
            _failure(
              400,
              'VALIDATION_FAILED',
              fields: [FieldError(field: field, code: 'INVALID_FORMAT', message: 'Check this')],
            ),
          ),
        );
        expect(find.descendant(of: find.byKey(Key(key)), matching: find.text('Check this')), findsOneWidget);
        expect(find.byKey(const Key('studentForm.error')), findsNothing);
      });
    }

    testWidgets('shows the error on which guardian is primary under that guardian', (tester) async {
      await pump(
        tester,
        refused(
          _failure(
            400,
            'VALIDATION_FAILED',
            fields: const [FieldError(field: 'guardians[0].isPrimary', code: 'INVALID_VALUE', message: 'Choose one')],
          ),
        ),
      );
      expect(find.byKey(const Key('studentForm.guardian.0.primaryError')), findsOneWidget);
      expect(find.text('Choose one'), findsOneWidget);
    });

    testWidgets('says a refusal that names no field above the form', (tester) async {
      await pump(tester, refused(_failure(409, 'ROLE_CONFLICT')));
      expect(
        find.descendant(
          of: find.byKey(const Key('studentForm.error')),
          matching: find.text("A guardian's email belongs to a platform account, which can't also be a parent."),
        ),
        findsOneWidget,
      );
    });

    testWidgets('says an error on a row that is not there above the form, not nowhere', (tester) async {
      await pump(
        tester,
        refused(
          _failure(
            400,
            'VALIDATION_FAILED',
            fields: const [FieldError(field: 'guardians[6].firstName', code: 'TOO_SHORT', message: 'Name needed')],
          ),
        ),
      );
      expect(find.byKey(const Key('studentForm.error')), findsOneWidget);
    });
  });

  group('before the form is ready', () {
    testWidgets('shows a placeholder while it loads', (tester) async {
      await pump(tester, const StudentFormLoading());
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('says why it could not be read, and starts again on Try again', (tester) async {
      await pump(tester, const StudentFormFailed(ApiFailure.network()));
      expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const StudentFormStarted())).called(1);
    });

    testWidgets('says there is no access, with no retry', (tester) async {
      await pump(tester, StudentFormFailed(_failure(403, 'FORBIDDEN')));
      expect(find.byKey(const Key('studentForm.forbidden')), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('says a class and section are needed first when the Institution has none', (tester) async {
      await pump(
        tester,
        const StudentFormReady(
          options: SectionOptions(years: [], sections: []),
          guardians: [GuardianEntry(0, GuardianTexts(), isPrimary: true)],
          nextRowId: 1,
        ),
      );
      expect(find.byKey(const Key('studentForm.noPlaces')), findsOneWidget);
      expect(find.text('Set up a class first'), findsOneWidget);
    });
  });

  group('once saved', () {
    Future<bool?> saveWith(WidgetTester tester, StudentSaved saved) async {
      whenListen(bloc, Stream.value(StudentFormSaved(saved)), initialState: _empty);
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
            builder: (_, _) => BlocProvider<StudentFormBloc>.value(value: bloc, child: const StudentFormView()),
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
      return result;
    }

    testWidgets('closes with a message and tells the screen behind it', (tester) async {
      final result = await saveWith(
        tester,
        const StudentSaved(
          Student(id: 'p1', institutionId: 'i1', firstName: 'Asha', lastName: 'Rao'),
        ),
      );
      expect(result, isTrue);
      expect(find.text('Asha Rao added'), findsOneWidget);
    });

    testWidgets('adds a line for each second look the server asked for', (tester) async {
      await saveWith(
        tester,
        const StudentSaved(
          Student(id: 'p1', institutionId: 'i1', firstName: 'Asha'),
          warnings: ['SECTION_OVER_CAPACITY', 'AADHAAR_EXISTS_IN_SOCIETY', 'SOMETHING_NEW'],
        ),
      );
      expect(
        find.text(
          'Asha added The section is now over its capacity. Another Institution of the Society holds this Aadhaar number.',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('reads whole at a large text scale on a small phone, with its guardians', (tester) async {
    await pump(tester, _filled, textScale: 2, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    // "Choose" (the hint of an empty date field) is wider than the field at this size, so it cannot fit any box here.
    expect(clippedParagraphs(tester, unbreakable: 184), isEmpty);
    await tester.scrollUntilVisible(
      find.byKey(const Key('studentForm.addGuardian')),
      300,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
