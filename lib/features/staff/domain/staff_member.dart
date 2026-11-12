import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:equatable/equatable.dart';

/// PRD 11.4: 1 Full time, 2 Part time, 3 Visiting, 4 Contract.
enum EmploymentType {
  fullTime(1),
  partTime(2),
  visiting(3),
  contract(4);

  new(this.code);

  final int code;

  static EmploymentType? fromCode(Object? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

/// One row of the staff list (STF-01); the profile has the rest. Names of the designation and category are not in the
/// row, only their IDs: the masters give the names.
class StaffSummary extends Equatable {
  const new({
    required this.id,
    required this.firstName,
    required this.classCategoryId,
    required this.mobile,
    required this.isBlocked,
    this.lastName,
    this.employeeCode,
    this.designationId,
  });

  final String id;
  final String firstName;
  final String? lastName;
  final String? employeeCode;
  final String? designationId;
  final String classCategoryId;
  final Phone mobile;

  /// The "Blocked" badge (STF-06).
  final bool isBlocked;

  String get fullName => [firstName, ?lastName].join(' ');

  @override
  List<Object?> get props => [id, firstName, lastName, employeeCode, designationId, classCategoryId, mobile, isBlocked];
}

/// A row of the list with the names its IDs stand for.
class StaffListEntry extends Equatable {
  const new(this.summary, {this.categoryName, this.designationName});

  final StaffSummary summary;
  final String? designationName;

  /// Null when the master no longer shows the category (it was hidden, MST-01).
  final String? categoryName;

  @override
  List<Object?> get props => [summary, designationName, categoryName];
}

/// One entry of the education list (PRD 7.5).
class Education extends Equatable {
  const new({required this.degree, this.qualification, this.specialization, this.institutionName, this.yearOfPassing});

  final String degree;
  final String? qualification;
  final String? specialization;
  final String? institutionName;
  final int? yearOfPassing;

  @override
  List<Object?> get props => [degree, qualification, specialization, institutionName, yearOfPassing];
}

/// One guardian or emergency contact (PRD 7.5).
class EmergencyContact extends Equatable {
  const new({
    required this.contactName,
    required this.phone,
    required this.isPrimary,
    this.relation,
    this.alternateNumber,
  });

  final String contactName;
  final String? relation;
  final Phone phone;
  final String? alternateNumber;
  final bool isPrimary;

  @override
  List<Object?> get props => [contactName, relation, phone, alternateNumber, isPrimary];
}

/// The section a teacher leads as class teacher in an academic year (STF-03, STF-09).
class ClassTeacherAssignment extends Equatable {
  const new({required this.academicYearId, required this.sectionId});

  final String academicYearId;
  final String sectionId;

  @override
  List<Object?> get props => [academicYearId, sectionId];
}

/// A staff member as the profile shows them (STF-03).
class StaffMember extends Equatable {
  const new({
    required this.id,
    required this.homeInstitutionId,
    required this.email,
    required this.firstName,
    required this.classCategoryId,
    required this.mobile,
    required this.address,
    required this.educations,
    required this.emergencyContacts,
    required this.isBlocked,
    required this.version,
    this.subjectIds = const [],
    this.institutionIds = const [],
    this.classTeachers = const [],
    this.aadhaarMasked,
    this.lastName,
    this.employeeCode,
    this.gender,
    this.dateOfBirth,
    this.bloodGroup,
    this.nationality,
    this.photoFileId,
    this.designationId,
    this.alternateNumber,
    this.joiningDate,
    this.resignationDate,
    this.employmentType,
  });

  final String id;
  final String homeInstitutionId;

  /// The login.
  final String email;
  final String firstName;
  final String? lastName;
  final String? employeeCode;
  final Gender? gender;

  /// A day, `YYYY-MM-DD`.
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? nationality;
  final String? photoFileId;
  final String? designationId;
  final String classCategoryId;
  final Phone mobile;
  final String? alternateNumber;
  final Address address;
  final String? joiningDate;
  final String? resignationDate;
  final EmploymentType? employmentType;
  final List<Education> educations;
  final List<EmergencyContact> emergencyContacts;
  final bool isBlocked;
  final int version;

  /// The subjects they can teach (STF-08).
  final List<String> subjectIds;

  /// The Institutions besides the home one that they may see (STF-10).
  final List<String> institutionIds;

  /// The sections they lead as class teacher, one for each academic year (STF-09).
  final List<ClassTeacherAssignment> classTeachers;

  /// The Aadhaar number with all but the last four digits hidden, such as "XXXX XXXX 1234"; null when none is set. The
  /// API sends it to Owners and Admins only (STF-03).
  final String? aadhaarMasked;

  String get fullName => [firstName, ?lastName].join(' ');

  @override
  List<Object?> get props => [
    id,
    homeInstitutionId,
    email,
    firstName,
    lastName,
    employeeCode,
    gender,
    dateOfBirth,
    bloodGroup,
    nationality,
    photoFileId,
    designationId,
    classCategoryId,
    mobile,
    alternateNumber,
    address,
    joiningDate,
    resignationDate,
    employmentType,
    educations,
    emergencyContacts,
    isBlocked,
    version,
    subjectIds,
    institutionIds,
    classTeachers,
    aadhaarMasked,
  ];
}
