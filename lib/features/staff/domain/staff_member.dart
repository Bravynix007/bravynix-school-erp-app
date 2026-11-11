import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:equatable/equatable.dart';

/// The blood groups a record can hold (DDD 9.5).
const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

/// PRD 11.2: 1 Male, 2 Female, 3 Other.
enum Gender {
  male(1),
  female(2),
  other(3);

  new(this.code);

  final int code;

  static Gender? fromCode(Object? code) {
    for (final gender in values) {
      if (gender.code == code) return gender;
    }
    return null;
  }
}

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

/// Where a staff member lives. The place is given by master IDs, which the screen turns into names.
class StaffAddress extends Equatable {
  const new({this.line1, this.line2, this.countryId, this.stateId, this.cityId, this.pincode});

  final String? line1;
  final String? line2;
  final String? countryId;
  final String? stateId;
  final String? cityId;
  final String? pincode;

  bool get isEmpty =>
      line1 == null && line2 == null && countryId == null && stateId == null && cityId == null && pincode == null;

  @override
  List<Object?> get props => [line1, line2, countryId, stateId, cityId, pincode];
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

/// A staff member as the profile shows them (STF-03), without the access and identity fields that A3 and A4 add.
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
  final StaffAddress address;
  final String? joiningDate;
  final String? resignationDate;
  final EmploymentType? employmentType;
  final List<Education> educations;
  final List<EmergencyContact> emergencyContacts;
  final bool isBlocked;
  final int version;

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
  ];
}
