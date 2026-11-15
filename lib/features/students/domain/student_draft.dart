import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:equatable/equatable.dart';

/// What a student's personal fields are when the form is sent (STU-02). An empty field is null.
class StudentDraft extends Equatable {
  const new({
    required this.firstName,
    required this.mobile,
    this.lastName,
    this.gender,
    this.dateOfBirth,
    this.bloodGroup,
    this.nationality,
    this.photoFileId,
    this.admissionNo,
    this.admissionDate,
    this.contactEmail,
    this.alternateNumber,
    this.address = const Address(),
  });

  final String firstName;
  final String? lastName;
  final Gender? gender;
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? nationality;

  /// A photo uploaded for this form; null when none.
  final String? photoFileId;
  final String? admissionNo;

  /// The day the first placement begins; today when null.
  final String? admissionDate;
  final String? contactEmail;
  final Phone mobile;
  final String? alternateNumber;
  final Address address;

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    gender,
    dateOfBirth,
    bloodGroup,
    nationality,
    photoFileId,
    admissionNo,
    admissionDate,
    contactEmail,
    mobile,
    alternateNumber,
    address,
  ];
}

/// The class and section a new student starts in, and the roll number there (STU-02 `enrolment`).
class EnrolmentDraft extends Equatable {
  const new({
    required this.academicYearId,
    required this.classId,
    required this.sectionId,
    required this.rollNumber,
  });

  final String academicYearId;
  final String classId;
  final String sectionId;
  final String rollNumber;

  @override
  List<Object?> get props => [academicYearId, classId, sectionId, rollNumber];
}

/// PRD 7.6, DDD 9.6: 1 Father, 2 Mother, 3 Guardian, 4 Grandparent, 5 Sibling, 6 Other.
enum GuardianRelation {
  father(1),
  mother(2),
  guardian(3),
  grandparent(4),
  sibling(5),
  other(6);

  new(this.code);

  final int code;

  static GuardianRelation? fromCode(Object? code) {
    for (final relation in values) {
      if (relation.code == code) return relation;
    }
    return null;
  }
}

/// One parent or guardian of a new student. An email that belongs to a person links that person's login; a new one
/// makes a Pending account.
class GuardianDraft extends Equatable {
  const new({
    required this.firstName,
    required this.relation,
    required this.phone,
    required this.isPrimary,
    required this.isEmergencyContact,
    this.lastName,
    this.alternatePhone,
    this.email,
    this.occupation,
  });

  final String firstName;
  final String? lastName;

  /// Null until chosen; the API names the field.
  final GuardianRelation? relation;
  final Phone phone;
  final String? alternatePhone;
  final String? email;
  final String? occupation;
  final bool isPrimary;
  final bool isEmergencyContact;

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    relation,
    phone,
    alternatePhone,
    email,
    occupation,
    isPrimary,
    isEmergencyContact,
  ];
}

/// The numbers a new student's record holds (STU-02 `identity`). Each is null when not given.
class IdentityDraft extends Equatable {
  const new({this.aadhaarNumber, this.birthCertificateNumber});

  /// The twelve digits.
  final String? aadhaarNumber;
  final String? birthCertificateNumber;

  bool get isEmpty => aadhaarNumber == null && birthCertificateNumber == null;

  @override
  List<Object?> get props => [aadhaarNumber, birthCertificateNumber];
}
