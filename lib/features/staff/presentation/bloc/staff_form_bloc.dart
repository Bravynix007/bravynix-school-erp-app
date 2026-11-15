import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/core/model/typed_text.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/place_choice.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_draft.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:equatable/equatable.dart';

/// PRD 7.5: a staff record holds up to 20 education lines and 10 emergency contacts (the API refuses more).
const maxEducations = 20;
const maxEmergencyContacts = 10;

/// The text fields of the form, as typed. An empty one is read as not set.
class StaffTexts extends Equatable {
  const new({
    required this.firstName,
    this.lastName = '',
    this.email = '',
    this.mobileCountryCode = '',
    this.mobileNumber = '',
    this.alternateNumber = '',
    this.nationality = '',
    this.employeeCode = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.pincode = '',
  });

  final String firstName;
  final String lastName;
  final String email;
  final String mobileCountryCode;
  final String mobileNumber;
  final String alternateNumber;
  final String nationality;
  final String employeeCode;
  final String addressLine1;
  final String addressLine2;
  final String pincode;

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    email,
    mobileCountryCode,
    mobileNumber,
    alternateNumber,
    nationality,
    employeeCode,
    addressLine1,
    addressLine2,
    pincode,
  ];
}

/// The text of one education line, as typed.
class EducationTexts extends Equatable {
  const new({
    this.degree = '',
    this.qualification = '',
    this.specialization = '',
    this.institutionName = '',
    this.yearOfPassing = '',
  });

  factory fromEducation(Education line) => EducationTexts(
    degree: line.degree,
    qualification: line.qualification ?? '',
    specialization: line.specialization ?? '',
    institutionName: line.institutionName ?? '',
    yearOfPassing: line.yearOfPassing?.toString() ?? '',
  );

  final String degree;
  final String qualification;
  final String specialization;
  final String institutionName;
  final String yearOfPassing;

  @override
  List<Object?> get props => [degree, qualification, specialization, institutionName, yearOfPassing];
}

/// The text of one emergency contact, as typed.
class ContactTexts extends Equatable {
  const new({
    this.contactName = '',
    this.relation = '',
    this.countryCode = '',
    this.number = '',
    this.alternateNumber = '',
  });

  factory fromContact(EmergencyContact contact) => ContactTexts(
    contactName: contact.contactName,
    relation: contact.relation ?? '',
    countryCode: contact.phone.countryCode,
    number: contact.phone.number,
    alternateNumber: contact.alternateNumber ?? '',
  );

  final String contactName;
  final String relation;
  final String countryCode;
  final String number;
  final String alternateNumber;

  @override
  List<Object?> get props => [contactName, relation, countryCode, number, alternateNumber];
}

/// One education line of the form. [id] names the row for as long as the form is open: the first rows of an edit take
/// 0, 1, 2 … in the order the record holds them, and a row added later takes the next number, so a row keeps its place
/// on the screen when another is removed.
class EducationEntry extends Equatable {
  const new(this.id, this.texts);

  final int id;
  final EducationTexts texts;

  @override
  List<Object?> get props => [id, texts];
}

/// One emergency contact of the form; see [EducationEntry] for [id].
class ContactEntry extends Equatable {
  const new(this.id, this.texts, {this.isPrimary = false});

  final int id;
  final ContactTexts texts;
  final bool isPrimary;

  @override
  List<Object?> get props => [id, texts, isPrimary];
}

sealed class StaffFormEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the form, and Try again after the lists could not be read.
final class StaffFormStarted extends StaffFormEvent {
  const new();
}

final class StaffGenderChosen extends StaffFormEvent {
  const new(this.gender);

  final Gender? gender;

  @override
  List<Object?> get props => [gender];
}

final class StaffBloodGroupChosen extends StaffFormEvent {
  const new(this.bloodGroup);

  final String? bloodGroup;

  @override
  List<Object?> get props => [bloodGroup];
}

final class StaffBirthDateChosen extends StaffFormEvent {
  const new(this.day);

  /// `YYYY-MM-DD`, or null to clear it.
  final String? day;

  @override
  List<Object?> get props => [day];
}

final class StaffJoiningDateChosen extends StaffFormEvent {
  const new(this.day);

  final String? day;

  @override
  List<Object?> get props => [day];
}

final class StaffResignationDateChosen extends StaffFormEvent {
  const new(this.day);

  final String? day;

  @override
  List<Object?> get props => [day];
}

final class StaffEmploymentTypeChosen extends StaffFormEvent {
  const new(this.type);

  final EmploymentType? type;

  @override
  List<Object?> get props => [type];
}

final class StaffCategoryChosen extends StaffFormEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class StaffDesignationChosen extends StaffFormEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

/// The photo upload finished with [id], or the person removed the photo they chose (null).
final class StaffPhotoChosen extends StaffFormEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class StaffEducationAdded extends StaffFormEvent {
  const new();
}

final class StaffEducationEdited extends StaffFormEvent {
  const new(this.id, this.texts);

  final int id;
  final EducationTexts texts;

  @override
  List<Object?> get props => [id, texts];
}

final class StaffEducationRemoved extends StaffFormEvent {
  const new(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

final class StaffContactAdded extends StaffFormEvent {
  const new();
}

final class StaffContactEdited extends StaffFormEvent {
  const new(this.id, this.texts);

  final int id;
  final ContactTexts texts;

  @override
  List<Object?> get props => [id, texts];
}

final class StaffContactRemoved extends StaffFormEvent {
  const new(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Makes contact [id] the primary one, or no longer primary. At most one contact is primary, so choosing one
/// takes the mark from the other.
final class StaffContactPrimaryChosen extends StaffFormEvent {
  const new(this.id, {required this.isPrimary});

  final int id;
  final bool isPrimary;

  @override
  List<Object?> get props => [id, isPrimary];
}

final class StaffFormSubmitted extends StaffFormEvent {
  const new(this.texts, this.place);

  final StaffTexts texts;

  /// The place chosen in the address.
  final PlaceChoice place;

  @override
  List<Object?> get props => [texts, place];
}

sealed class StaffFormState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class StaffFormLoading extends StaffFormState {
  const new();
}

/// The staff member to edit, or the lists the form needs, could not be read.
class StaffFormFailed extends StaffFormState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The form: what is chosen, and the lists it is chosen from. [existing] is set when a staff member is edited.
/// [photoFileId] is a photo uploaded in this form; null keeps the record's own. The place of the address is chosen
/// through its own `PlaceBloc`.
class StaffFormReady extends StaffFormState {
  const new({
    required this.categories,
    required this.designations,
    required this.educations,
    required this.contacts,
    required this.nextRowId,
    this.existing,
    this.gender,
    this.bloodGroup,
    this.dateOfBirth,
    this.joiningDate,
    this.resignationDate,
    this.employmentType,
    this.categoryId,
    this.designationId,
    this.photoFileId,
    this.saving = false,
    this.failure,
    this.failedEducationIds = const [],
    this.failedContactIds = const [],
  });

  final StaffMember? existing;
  final List<MasterEntry> categories;
  final List<MasterEntry> designations;
  final Gender? gender;
  final String? bloodGroup;
  final String? dateOfBirth;
  final String? joiningDate;
  final String? resignationDate;
  final EmploymentType? employmentType;
  final String? categoryId;
  final String? designationId;
  final String? photoFileId;
  final List<EducationEntry> educations;
  final List<ContactEntry> contacts;

  /// The number the next added row takes.
  final int nextRowId;
  final bool saving;

  /// The last save.
  final ApiFailure? failure;

  /// The rows the last save sent, in the order it sent them: the API names a row by its place in that order, and rows
  /// are added and removed afterwards, so an error is shown under the row it was about and not the one now in its place.
  final List<int> failedEducationIds;
  final List<int> failedContactIds;

  bool get isEdit => existing != null;
  bool get canAddEducation => educations.length < maxEducations;
  bool get canAddContact => contacts.length < maxEmergencyContacts;

  StaffFormReady copyWith({
    Gender? Function()? gender,
    String? Function()? bloodGroup,
    String? Function()? dateOfBirth,
    String? Function()? joiningDate,
    String? Function()? resignationDate,
    EmploymentType? Function()? employmentType,
    String? Function()? categoryId,
    String? Function()? designationId,
    String? Function()? photoFileId,
    List<EducationEntry>? educations,
    List<ContactEntry>? contacts,
    int? nextRowId,
    bool? saving,
    ApiFailure? Function()? failure,
    List<int>? failedEducationIds,
    List<int>? failedContactIds,
  }) => StaffFormReady(
    existing: existing,
    categories: categories,
    designations: designations,
    gender: gender == null ? this.gender : gender(),
    bloodGroup: bloodGroup == null ? this.bloodGroup : bloodGroup(),
    dateOfBirth: dateOfBirth == null ? this.dateOfBirth : dateOfBirth(),
    joiningDate: joiningDate == null ? this.joiningDate : joiningDate(),
    resignationDate: resignationDate == null ? this.resignationDate : resignationDate(),
    employmentType: employmentType == null ? this.employmentType : employmentType(),
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    designationId: designationId == null ? this.designationId : designationId(),
    photoFileId: photoFileId == null ? this.photoFileId : photoFileId(),
    educations: educations ?? this.educations,
    contacts: contacts ?? this.contacts,
    nextRowId: nextRowId ?? this.nextRowId,
    saving: saving ?? this.saving,
    failure: failure == null ? this.failure : failure(),
    failedEducationIds: failedEducationIds ?? this.failedEducationIds,
    failedContactIds: failedContactIds ?? this.failedContactIds,
  );

  @override
  List<Object?> get props => [
    existing,
    categories,
    designations,
    gender,
    bloodGroup,
    dateOfBirth,
    joiningDate,
    resignationDate,
    employmentType,
    categoryId,
    designationId,
    photoFileId,
    educations,
    contacts,
    nextRowId,
    saving,
    failure,
    failedEducationIds,
    failedContactIds,
  ];
}

class StaffFormSaved extends StaffFormState {
  const new(this.member);

  final StaffMember member;

  @override
  List<Object?> get props => [member];
}

/// Adds a staff member at an Institution (STF-02) or changes one (STF-04), picking the category and designation from
/// the masters and keeping the education and emergency contact lists as rows.
class StaffFormBloc extends Bloc<StaffFormEvent, StaffFormState> {
  /// [institutionId] is where a new staff member is based; [staffId] set edits that staff member instead.
  new(this._staff, this._masters, {this.institutionId, this.staffId})
    : assert((institutionId == null) != (staffId == null), 'Add at an Institution, or edit one staff member'),
      super(const StaffFormLoading()) {
    on<StaffFormStarted>(_onStarted);
    on<StaffGenderChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(gender: () => event.gender))));
    on<StaffBloodGroupChosen>(
      (event, emit) => _ready((ready) => emit(ready.copyWith(bloodGroup: () => event.bloodGroup))),
    );
    on<StaffBirthDateChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(dateOfBirth: () => event.day))));
    on<StaffJoiningDateChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(joiningDate: () => event.day))));
    on<StaffResignationDateChosen>(
      (event, emit) => _ready((ready) => emit(ready.copyWith(resignationDate: () => event.day))),
    );
    on<StaffEmploymentTypeChosen>(
      (event, emit) => _ready((ready) => emit(ready.copyWith(employmentType: () => event.type))),
    );
    on<StaffCategoryChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(categoryId: () => event.id))));
    on<StaffDesignationChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(designationId: () => event.id))));
    on<StaffPhotoChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(photoFileId: () => event.id))));
    on<StaffEducationAdded>(_onEducationAdded);
    on<StaffEducationEdited>(_onEducationEdited);
    on<StaffEducationRemoved>(_onEducationRemoved);
    on<StaffContactAdded>(_onContactAdded);
    on<StaffContactEdited>(_onContactEdited);
    on<StaffContactRemoved>(_onContactRemoved);
    on<StaffContactPrimaryChosen>(_onContactPrimaryChosen);
    on<StaffFormSubmitted>(_onSubmitted);
  }

  final StaffRepository _staff;
  final MastersRepository _masters;

  /// Where a new staff member is based; null when one is edited.
  final String? institutionId;

  /// The staff member to edit; null when one is added.
  final String? staffId;

  void _ready(void Function(StaffFormReady ready) work) {
    if (state case final StaffFormReady ready) work(ready);
  }

  Future<void> _onStarted(StaffFormStarted event, Emitter<StaffFormState> emit) async {
    emit(const StaffFormLoading());
    try {
      final existing = staffId == null ? null : await _staff.member(staffId!);
      final categories = await _masters.entries(MasterType.classCategories);
      final designations = await _masters.entries(MasterType.designations);
      final educations = existing?.educations ?? const <Education>[];
      final contacts = existing?.emergencyContacts ?? const <EmergencyContact>[];
      emit(
        StaffFormReady(
          existing: existing,
          categories: categories,
          designations: designations,
          gender: existing?.gender,
          bloodGroup: existing?.bloodGroup,
          dateOfBirth: existing?.dateOfBirth,
          joiningDate: existing?.joiningDate,
          resignationDate: existing?.resignationDate,
          employmentType: existing?.employmentType,
          categoryId: existing?.classCategoryId,
          designationId: existing?.designationId,
          educations: [
            for (final (index, line) in educations.indexed) EducationEntry(index, EducationTexts.fromEducation(line)),
          ],
          contacts: [
            for (final (index, contact) in contacts.indexed)
              ContactEntry(educations.length + index, ContactTexts.fromContact(contact), isPrimary: contact.isPrimary),
          ],
          nextRowId: educations.length + contacts.length,
        ),
      );
    } on ApiFailure catch (failure) {
      emit(StaffFormFailed(failure));
    }
  }

  void _onEducationAdded(StaffEducationAdded event, Emitter<StaffFormState> emit) => _ready((ready) {
    if (!ready.canAddEducation) return;
    emit(
      ready.copyWith(
        educations: [...ready.educations, EducationEntry(ready.nextRowId, const EducationTexts())],
        nextRowId: ready.nextRowId + 1,
      ),
    );
  });

  void _onEducationEdited(StaffEducationEdited event, Emitter<StaffFormState> emit) => _ready(
    (ready) => emit(
      ready.copyWith(
        educations: [
          for (final entry in ready.educations)
            if (entry.id == event.id) EducationEntry(entry.id, event.texts) else entry,
        ],
      ),
    ),
  );

  void _onEducationRemoved(StaffEducationRemoved event, Emitter<StaffFormState> emit) => _ready(
    (ready) => emit(
      ready.copyWith(
        educations: [
          for (final entry in ready.educations)
            if (entry.id != event.id) entry,
        ],
      ),
    ),
  );

  void _onContactAdded(StaffContactAdded event, Emitter<StaffFormState> emit) => _ready((ready) {
    if (!ready.canAddContact) return;
    emit(
      ready.copyWith(
        contacts: [
          ...ready.contacts,
          ContactEntry(ready.nextRowId, const ContactTexts(countryCode: Phone.indiaDialCode)),
        ],
        nextRowId: ready.nextRowId + 1,
      ),
    );
  });

  void _onContactEdited(StaffContactEdited event, Emitter<StaffFormState> emit) => _ready(
    (ready) => emit(
      ready.copyWith(
        contacts: [
          for (final entry in ready.contacts)
            if (entry.id == event.id) ContactEntry(entry.id, event.texts, isPrimary: entry.isPrimary) else entry,
        ],
      ),
    ),
  );

  void _onContactRemoved(StaffContactRemoved event, Emitter<StaffFormState> emit) => _ready(
    (ready) => emit(
      ready.copyWith(
        contacts: [
          for (final entry in ready.contacts)
            if (entry.id != event.id) entry,
        ],
      ),
    ),
  );

  void _onContactPrimaryChosen(StaffContactPrimaryChosen event, Emitter<StaffFormState> emit) => _ready(
    (ready) => emit(
      ready.copyWith(
        contacts: [
          for (final entry in ready.contacts)
            ContactEntry(entry.id, entry.texts, isPrimary: entry.id == event.id && event.isPrimary),
        ],
      ),
    ),
  );

  Future<void> _onSubmitted(StaffFormSubmitted event, Emitter<StaffFormState> emit) async {
    if (state case final StaffFormReady ready when !ready.saving) {
      emit(ready.copyWith(saving: true, failure: () => null, failedEducationIds: const [], failedContactIds: const []));
      final draft = _draft(ready, event.texts, event.place);
      try {
        final existing = ready.existing;
        final saved = existing == null
            ? await _staff.create(institutionId!, draft)
            : await _staff.update(existing.id, existing.version, draft);
        emit(StaffFormSaved(saved));
      } on ApiFailure catch (failure) {
        // The rows can be changed while the save is out; keep what the form holds now, not what it held at the start.
        if (state case final StaffFormReady now) {
          emit(
            now.copyWith(
              saving: false,
              failure: () => failure,
              failedEducationIds: [for (final entry in ready.educations) entry.id],
              failedContactIds: [for (final entry in ready.contacts) entry.id],
            ),
          );
        }
      }
    }
  }

  StaffDraft _draft(StaffFormReady ready, StaffTexts texts, PlaceChoice place) => StaffDraft(
    // An edit never sends the email; the draft carries none.
    email: ready.isEdit ? '' : texts.email.trim(),
    firstName: texts.firstName.trim(),
    lastName: TypedText.text(texts.lastName),
    employeeCode: TypedText.text(texts.employeeCode),
    gender: ready.gender,
    dateOfBirth: ready.dateOfBirth,
    bloodGroup: ready.bloodGroup,
    nationality: TypedText.text(texts.nationality),
    photoFileId: ready.photoFileId,
    designationId: ready.designationId,
    // A category is required; the API names the field when none is chosen.
    classCategoryId: ready.categoryId ?? '',
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
    joiningDate: ready.joiningDate,
    resignationDate: ready.resignationDate,
    employmentType: ready.employmentType,
    educations: [
      for (final entry in ready.educations)
        Education(
          degree: entry.texts.degree.trim(),
          qualification: TypedText.text(entry.texts.qualification),
          specialization: TypedText.text(entry.texts.specialization),
          institutionName: TypedText.text(entry.texts.institutionName),
          yearOfPassing: int.tryParse(entry.texts.yearOfPassing.trim()),
        ),
    ],
    emergencyContacts: [
      for (final entry in ready.contacts)
        EmergencyContact(
          contactName: entry.texts.contactName.trim(),
          relation: TypedText.text(entry.texts.relation),
          phone: Phone.typedOrBlank(entry.texts.countryCode, entry.texts.number),
          alternateNumber: TypedText.digits(entry.texts.alternateNumber),
          isPrimary: entry.isPrimary,
        ),
    ],
  );
}
