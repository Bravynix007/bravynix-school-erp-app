import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/student_draft.dart';
import 'package:equatable/equatable.dart';

/// One parent or guardian of a student as the profile shows them (GDN-01, in STU-03).
class Guardian extends Equatable {
  const new({
    required this.id,
    required this.firstName,
    required this.phone,
    required this.isPrimary,
    required this.isEmergencyContact,
    this.lastName,
    this.relation,
    this.alternatePhone,
    this.email,
    this.occupation,
  });

  final String id;
  final String firstName;
  final String? lastName;

  /// Null when the API sends a relation this app does not know yet.
  final GuardianRelation? relation;
  final Phone phone;
  final String? alternatePhone;
  final String? email;
  final String? occupation;
  final bool isPrimary;
  final bool isEmergencyContact;

  String get fullName => [firstName, ?lastName].join(' ');

  @override
  List<Object?> get props => [
    id,
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

/// The numbers a student's record holds, as the profile shows them (STU-03): the Aadhaar masked, the birth certificate
/// number whole. Each is null when not set.
class StudentIdentity extends Equatable {
  const new({this.aadhaarMasked, this.birthCertificateNumber});

  final String? aadhaarMasked;
  final String? birthCertificateNumber;

  @override
  List<Object?> get props => [aadhaarMasked, birthCertificateNumber];
}

/// A student as an Owner or Admin reads them (STU-03): the record, where the child sits and the guardians.
class StudentRecord extends Equatable {
  const new({
    required this.id,
    required this.institutionId,
    required this.firstName,
    required this.mobile,
    required this.address,
    required this.guardians,
    required this.identity,
    required this.isBlocked,
    required this.isActive,
    required this.version,
    this.lastName,
    this.admissionNo,
    this.admissionDate,
    this.gender,
    this.dateOfBirth,
    this.bloodGroup,
    this.nationality,
    this.photoFileId,
    this.contactEmail,
    this.alternateNumber,
    this.placement,
  });

  final String id;
  final String institutionId;
  final String? admissionNo;
  final String firstName;
  final String? lastName;
  final Gender? gender;
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? nationality;
  final String? photoFileId;
  final String? admissionDate;
  final String? contactEmail;

  /// Null when the student has no number of their own.
  final Phone? mobile;
  final String? alternateNumber;
  final Address address;

  /// The class and section the student sits in, or sat in last when they are deactivated; null when they never had one.
  final StudentPlacement? placement;
  final List<Guardian> guardians;
  final StudentIdentity identity;

  /// The guardians' access to this child is blocked (STU-06).
  final bool isBlocked;

  /// False once the student is deactivated (STU-05, or completing the final class).
  final bool isActive;
  final int version;

  String get fullName => [firstName, ?lastName].join(' ');

  @override
  List<Object?> get props => [
    id,
    institutionId,
    admissionNo,
    firstName,
    lastName,
    gender,
    dateOfBirth,
    bloodGroup,
    nationality,
    photoFileId,
    admissionDate,
    contactEmail,
    mobile,
    alternateNumber,
    address,
    placement,
    guardians,
    identity,
    isBlocked,
    isActive,
    version,
  ];
}

/// A student with the names of the class, section and places their IDs stand for, as the profile shows them.
class StudentProfile extends Equatable {
  const new(this.record, {this.placeName, this.countryName, this.stateName, this.cityName});

  final StudentRecord record;

  /// "Class 5 · A"; null when the student has no placement or the section is no longer offered.
  final String? placeName;
  final String? countryName;
  final String? stateName;
  final String? cityName;

  @override
  List<Object?> get props => [record, placeName, countryName, stateName, cityName];
}
