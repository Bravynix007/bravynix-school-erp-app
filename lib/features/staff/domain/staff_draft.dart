import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:equatable/equatable.dart';

/// What the add and edit form sends (STF-02, STF-04). An empty field is null. The email is the login: it is sent when a
/// staff member is added and never when one is edited (STF-13 changes it).
class StaffDraft extends Equatable {
  const new({
    required this.firstName,
    required this.mobile,
    required this.classCategoryId,
    this.email = '',
    this.lastName,
    this.employeeCode,
    this.gender,
    this.dateOfBirth,
    this.bloodGroup,
    this.nationality,
    this.photoFileId,
    this.designationId,
    this.alternateNumber,
    this.address = const StaffAddress(),
    this.joiningDate,
    this.resignationDate,
    this.employmentType,
    this.educations = const [],
    this.emergencyContacts = const [],
  });

  final String email;
  final String firstName;
  final String? lastName;
  final String? employeeCode;
  final Gender? gender;
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? nationality;

  /// A photo uploaded for this save. Null keeps the one the record has (or none).
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

  @override
  List<Object?> get props => [
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
  ];
}
