import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/model/aadhaar.dart';
import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/core/model/typed_text.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/validation/field_problems.dart';
import 'package:bravynix_school_erp/features/masters/domain/place_choice.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/student_draft.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:equatable/equatable.dart';

/// PRD 7.6: a student has one to five parents or guardians (the API refuses more).
const maxGuardians = 5;

/// The text fields of the form, as typed. An empty one is read as not set.
class StudentTexts extends Equatable {
  const new({
    required this.firstName,
    this.lastName = '',
    this.admissionNo = '',
    this.contactEmail = '',
    this.mobileCountryCode = '',
    this.mobileNumber = '',
    this.alternateNumber = '',
    this.nationality = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.pincode = '',
    this.rollNumber = '',
    this.aadhaar = '',
    this.birthCertificate = '',
  });

  final String firstName;
  final String lastName;
  final String admissionNo;
  final String contactEmail;
  final String mobileCountryCode;
  final String mobileNumber;
  final String alternateNumber;
  final String nationality;
  final String addressLine1;
  final String addressLine2;
  final String pincode;
  final String rollNumber;
  final String aadhaar;
  final String birthCertificate;

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    admissionNo,
    contactEmail,
    mobileCountryCode,
    mobileNumber,
    alternateNumber,
    nationality,
    addressLine1,
    addressLine2,
    pincode,
    rollNumber,
    aadhaar,
    birthCertificate,
  ];
}

/// The text of one guardian, as typed.
class GuardianTexts extends Equatable {
  const new({
    this.firstName = '',
    this.lastName = '',
    this.countryCode = '',
    this.number = '',
    this.alternatePhone = '',
    this.email = '',
    this.occupation = '',
  });

  final String firstName;
  final String lastName;
  final String countryCode;
  final String number;
  final String alternatePhone;
  final String email;
  final String occupation;

  @override
  List<Object?> get props => [firstName, lastName, countryCode, number, alternatePhone, email, occupation];
}

/// One guardian of the form. [id] names the row for as long as the form is open: the first row takes 0 and a row added
/// later takes the next number, so a row keeps its place on the screen when another is removed.
class GuardianEntry extends Equatable {
  const new(
    this.id,
    this.texts, {
    this.relation,
    this.isPrimary = false,
    this.isEmergencyContact = false,
  });

  final int id;
  final GuardianTexts texts;
  final GuardianRelation? relation;
  final bool isPrimary;
  final bool isEmergencyContact;

  GuardianEntry copyWith({
    GuardianTexts? texts,
    GuardianRelation? Function()? relation,
    bool? isPrimary,
    bool? isEmergencyContact,
  }) => GuardianEntry(
    id,
    texts ?? this.texts,
    relation: relation == null ? this.relation : relation(),
    isPrimary: isPrimary ?? this.isPrimary,
    isEmergencyContact: isEmergencyContact ?? this.isEmergencyContact,
  );

  @override
  List<Object?> get props => [id, texts, relation, isPrimary, isEmergencyContact];
}

sealed class StudentFormEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the form, and Try again after the years and sections could not be read.
final class StudentFormStarted extends StudentFormEvent {
  const new();
}

final class StudentGenderChosen extends StudentFormEvent {
  const new(this.gender);

  final Gender? gender;

  @override
  List<Object?> get props => [gender];
}

final class StudentBloodGroupChosen extends StudentFormEvent {
  const new(this.bloodGroup);

  final String? bloodGroup;

  @override
  List<Object?> get props => [bloodGroup];
}

final class StudentBirthDateChosen extends StudentFormEvent {
  const new(this.day);

  /// `YYYY-MM-DD`, or null to clear it.
  final String? day;

  @override
  List<Object?> get props => [day];
}

final class StudentAdmissionDateChosen extends StudentFormEvent {
  const new(this.day);

  final String? day;

  @override
  List<Object?> get props => [day];
}

final class StudentYearChosen extends StudentFormEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

/// A class was chosen; a section of another class is let go.
final class StudentClassChosen extends StudentFormEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class StudentSectionChosen extends StudentFormEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

/// The photo upload finished with [id], or the person removed the photo they chose (null).
final class StudentPhotoChosen extends StudentFormEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class StudentGuardianAdded extends StudentFormEvent {
  const new();
}

final class StudentGuardianEdited extends StudentFormEvent {
  const new(this.id, this.texts);

  final int id;
  final GuardianTexts texts;

  @override
  List<Object?> get props => [id, texts];
}

final class StudentGuardianRemoved extends StudentFormEvent {
  const new(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

final class StudentGuardianRelationChosen extends StudentFormEvent {
  const new(this.id, this.relation);

  final int id;
  final GuardianRelation? relation;

  @override
  List<Object?> get props => [id, relation];
}

/// Makes guardian [id] the primary one. Exactly one guardian is primary, so choosing one takes the mark from the other.
final class StudentGuardianPrimaryChosen extends StudentFormEvent {
  const new(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

final class StudentGuardianEmergencyChosen extends StudentFormEvent {
  const new(this.id, {required this.isEmergencyContact});

  final int id;
  final bool isEmergencyContact;

  @override
  List<Object?> get props => [id, isEmergencyContact];
}

final class StudentFormSubmitted extends StudentFormEvent {
  const new(this.texts, this.place);

  final StudentTexts texts;

  /// The place chosen in the address.
  final PlaceChoice place;

  @override
  List<Object?> get props => [texts, place];
}

sealed class StudentFormState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class StudentFormLoading extends StudentFormState {
  const new();
}

/// The years and sections the form chooses from could not be read.
class StudentFormFailed extends StudentFormState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The form: what is chosen, and the years, classes and sections it is chosen from. The place of the address is chosen
/// through its own `PlaceBloc`, and the text by the form's own controllers.
class StudentFormReady extends StudentFormState {
  const new({
    required this.options,
    required this.guardians,
    required this.nextRowId,
    this.gender,
    this.bloodGroup,
    this.dateOfBirth,
    this.admissionDate,
    this.yearId,
    this.classId,
    this.sectionId,
    this.photoFileId,
    this.saving = false,
    this.failure,
    this.failedGuardianIds = const [],
  });

  final SectionOptions options;
  final Gender? gender;
  final String? bloodGroup;
  final String? dateOfBirth;
  final String? admissionDate;
  final String? yearId;
  final String? classId;
  final String? sectionId;
  final String? photoFileId;
  final List<GuardianEntry> guardians;

  /// The number the next added row takes.
  final int nextRowId;
  final bool saving;

  /// The last save.
  final ApiFailure? failure;

  /// The rows the last save sent, in the order it sent them: the API names a row by its place in that order, and rows
  /// are added and removed afterwards, so an error is shown under the row it was about and not the one now in its
  /// place.
  final List<int> failedGuardianIds;

  bool get canAddGuardian => guardians.length < maxGuardians;

  /// The sections of the class chosen; none until a class is.
  List<SectionChoice> get sections => [
    for (final section in options.sections)
      if (section.classId == classId) section,
  ];

  StudentFormReady copyWith({
    Gender? Function()? gender,
    String? Function()? bloodGroup,
    String? Function()? dateOfBirth,
    String? Function()? admissionDate,
    String? Function()? yearId,
    String? Function()? classId,
    String? Function()? sectionId,
    String? Function()? photoFileId,
    List<GuardianEntry>? guardians,
    int? nextRowId,
    bool? saving,
    ApiFailure? Function()? failure,
    List<int>? failedGuardianIds,
  }) => StudentFormReady(
    options: options,
    gender: gender == null ? this.gender : gender(),
    bloodGroup: bloodGroup == null ? this.bloodGroup : bloodGroup(),
    dateOfBirth: dateOfBirth == null ? this.dateOfBirth : dateOfBirth(),
    admissionDate: admissionDate == null ? this.admissionDate : admissionDate(),
    yearId: yearId == null ? this.yearId : yearId(),
    classId: classId == null ? this.classId : classId(),
    sectionId: sectionId == null ? this.sectionId : sectionId(),
    photoFileId: photoFileId == null ? this.photoFileId : photoFileId(),
    guardians: guardians ?? this.guardians,
    nextRowId: nextRowId ?? this.nextRowId,
    saving: saving ?? this.saving,
    failure: failure == null ? this.failure : failure(),
    failedGuardianIds: failedGuardianIds ?? this.failedGuardianIds,
  );

  @override
  List<Object?> get props => [
    options,
    gender,
    bloodGroup,
    dateOfBirth,
    admissionDate,
    yearId,
    classId,
    sectionId,
    photoFileId,
    guardians,
    nextRowId,
    saving,
    failure,
    failedGuardianIds,
  ];
}

class StudentFormSaved extends StudentFormState {
  const new(this.saved);

  final StudentSaved saved;

  @override
  List<Object?> get props => [saved];
}

/// Adds a student to an Institution (STU-02): the personal details, the class and section they start in, one to five
/// guardians with one primary, and the Aadhaar and birth certificate numbers when known.
class StudentFormBloc extends Bloc<StudentFormEvent, StudentFormState> {
  new(this._students, this._options, this.institutionId) : super(const StudentFormLoading()) {
    on<StudentFormStarted>(_onStarted);
    on<StudentGenderChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(gender: () => event.gender))));
    on<StudentBloodGroupChosen>(
      (event, emit) => _ready((ready) => emit(ready.copyWith(bloodGroup: () => event.bloodGroup))),
    );
    on<StudentBirthDateChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(dateOfBirth: () => event.day))));
    on<StudentAdmissionDateChosen>(
      (event, emit) => _ready((ready) => emit(ready.copyWith(admissionDate: () => event.day))),
    );
    on<StudentYearChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(yearId: () => event.id))));
    on<StudentClassChosen>(_onClassChosen);
    on<StudentSectionChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(sectionId: () => event.id))));
    on<StudentPhotoChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(photoFileId: () => event.id))));
    on<StudentGuardianAdded>(_onGuardianAdded);
    on<StudentGuardianEdited>(
      (event, emit) => _guardian(emit, event.id, (entry) => entry.copyWith(texts: event.texts)),
    );
    on<StudentGuardianRemoved>(_onGuardianRemoved);
    on<StudentGuardianRelationChosen>(
      (event, emit) => _guardian(emit, event.id, (entry) => entry.copyWith(relation: () => event.relation)),
    );
    on<StudentGuardianPrimaryChosen>(_onGuardianPrimaryChosen);
    on<StudentGuardianEmergencyChosen>(
      (event, emit) =>
          _guardian(emit, event.id, (entry) => entry.copyWith(isEmergencyContact: event.isEmergencyContact)),
    );
    on<StudentFormSubmitted>(_onSubmitted);
  }

  final StudentsRepository _students;
  final SectionOptionsSource _options;

  /// Where the new student is placed.
  final String institutionId;

  void _ready(void Function(StudentFormReady ready) work) {
    if (state case final StudentFormReady ready) work(ready);
  }

  void _guardian(Emitter<StudentFormState> emit, int id, GuardianEntry Function(GuardianEntry entry) change) => _ready(
    (ready) => emit(
      ready.copyWith(
        guardians: [
          for (final entry in ready.guardians)
            if (entry.id == id) change(entry) else entry,
        ],
      ),
    ),
  );

  Future<void> _onStarted(StudentFormStarted event, Emitter<StudentFormState> emit) async {
    emit(const StudentFormLoading());
    try {
      final options = await _options.read(institutionId);
      emit(
        StudentFormReady(
          options: options,
          yearId: options.firstYearId,
          // The first guardian is the primary one until another is chosen: exactly one is.
          guardians: const [GuardianEntry(0, GuardianTexts(countryCode: Phone.indiaDialCode), isPrimary: true)],
          nextRowId: 1,
        ),
      );
    } on ApiFailure catch (failure) {
      emit(StudentFormFailed(failure));
    }
  }

  void _onClassChosen(StudentClassChosen event, Emitter<StudentFormState> emit) => _ready((ready) {
    final keeps = ready.options.sections.any(
      (section) => section.id == ready.sectionId && section.classId == event.id,
    );
    emit(ready.copyWith(classId: () => event.id, sectionId: keeps ? null : () => null));
  });

  void _onGuardianAdded(StudentGuardianAdded event, Emitter<StudentFormState> emit) => _ready((ready) {
    if (!ready.canAddGuardian) return;
    emit(
      ready.copyWith(
        guardians: [
          ...ready.guardians,
          GuardianEntry(ready.nextRowId, const GuardianTexts(countryCode: Phone.indiaDialCode)),
        ],
        nextRowId: ready.nextRowId + 1,
      ),
    );
  });

  void _onGuardianRemoved(StudentGuardianRemoved event, Emitter<StudentFormState> emit) => _ready((ready) {
    // A student keeps at least one guardian, and exactly one of them is primary.
    if (ready.guardians.length == 1) return;
    final left = [
      for (final entry in ready.guardians)
        if (entry.id != event.id) entry,
    ];
    emit(
      ready.copyWith(
        guardians: left.any((entry) => entry.isPrimary)
            ? left
            : [left.first.copyWith(isPrimary: true), ...left.skip(1)],
      ),
    );
  });

  void _onGuardianPrimaryChosen(StudentGuardianPrimaryChosen event, Emitter<StudentFormState> emit) => _ready(
    (ready) => emit(
      ready.copyWith(
        guardians: [for (final entry in ready.guardians) entry.copyWith(isPrimary: entry.id == event.id)],
      ),
    ),
  );

  Future<void> _onSubmitted(StudentFormSubmitted event, Emitter<StudentFormState> emit) async {
    if (state case final StudentFormReady ready when !ready.saving) {
      // The rows the save is about, in the order it names them.
      final rowIds = [for (final entry in ready.guardians) entry.id];
      final problem = _problems(ready, event.texts);
      if (problem != null) {
        emit(ready.copyWith(failure: () => problem, failedGuardianIds: rowIds));
        return;
      }
      emit(ready.copyWith(saving: true, failure: () => null, failedGuardianIds: const []));
      try {
        final saved = await _students.create(
          institutionId,
          _draft(ready, event.texts, event.place),
          enrolment: EnrolmentDraft(
            academicYearId: ready.yearId!,
            classId: ready.classId!,
            sectionId: ready.sectionId!,
            rollNumber: event.texts.rollNumber.trim(),
          ),
          guardians: [for (final entry in ready.guardians) _guardianDraft(entry)],
          identity: IdentityDraft(
            aadhaarNumber: Aadhaar.typed(event.texts.aadhaar),
            birthCertificateNumber: TypedText.text(event.texts.birthCertificate),
          ),
        );
        emit(StudentFormSaved(saved));
      } on ApiFailure catch (failure) {
        // The rows can be changed while the save is out; keep what the form holds now, not what it held at the start.
        if (state case final StudentFormReady now) {
          emit(now.copyWith(saving: false, failure: () => failure, failedGuardianIds: rowIds));
        }
      }
    }
  }

  /// What the form marks as required and has not been given, and an Aadhaar number that cannot be one: shown under the
  /// fields without asking the server, which would name them by their format and type.
  static ApiFailure? _problems(StudentFormReady ready, StudentTexts texts) {
    final problems = FieldProblems()
      ..requireText('firstName', texts.firstName)
      ..requireText('mobile.number', texts.mobileNumber)
      ..requireChoice('enrolment.academicYearId', ready.yearId)
      ..requireChoice('enrolment.classId', ready.classId)
      ..requireChoice('enrolment.sectionId', ready.sectionId)
      ..requireText('enrolment.rollNumber', texts.rollNumber);
    for (final (position, entry) in ready.guardians.indexed) {
      problems
        ..requireText('guardians[$position].firstName', entry.texts.firstName)
        ..requireChoice('guardians[$position].relation', entry.relation)
        ..requireText('guardians[$position].phone.number', entry.texts.number);
    }
    if (TypedText.text(texts.aadhaar) != null && Aadhaar.typed(texts.aadhaar) == null) {
      problems.add('identity.aadhaarNumber', 'INVALID_AADHAAR');
    }
    return problems.failure;
  }

  StudentDraft _draft(StudentFormReady ready, StudentTexts texts, PlaceChoice place) => StudentDraft(
    firstName: texts.firstName.trim(),
    lastName: TypedText.text(texts.lastName),
    gender: ready.gender,
    dateOfBirth: ready.dateOfBirth,
    bloodGroup: ready.bloodGroup,
    nationality: TypedText.text(texts.nationality),
    photoFileId: ready.photoFileId,
    admissionNo: TypedText.text(texts.admissionNo),
    admissionDate: ready.admissionDate,
    contactEmail: TypedText.text(texts.contactEmail),
    mobile: Phone.typedOrBlank(texts.mobileCountryCode, texts.mobileNumber),
    alternateNumber: TypedText.digits(texts.alternateNumber),
    address: Address.typed(
      line1: texts.addressLine1,
      line2: texts.addressLine2,
      pincode: texts.pincode,
      countryId: place.countryId,
      stateId: place.stateId,
      cityId: place.cityId,
    ),
  );

  GuardianDraft _guardianDraft(GuardianEntry entry) => GuardianDraft(
    firstName: entry.texts.firstName.trim(),
    lastName: TypedText.text(entry.texts.lastName),
    relation: entry.relation,
    phone: Phone.typedOrBlank(entry.texts.countryCode, entry.texts.number),
    alternatePhone: TypedText.digits(entry.texts.alternatePhone),
    email: TypedText.text(entry.texts.email),
    occupation: TypedText.text(entry.texts.occupation),
    isPrimary: entry.isPrimary,
    isEmergencyContact: entry.isEmergencyContact,
  );
}
