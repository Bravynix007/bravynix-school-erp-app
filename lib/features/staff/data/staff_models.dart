import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';

/// JSON → domain for STF-01 and STF-03. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class StaffModels {
  static StaffSummary summary(Object? raw) {
    final json = jsonObject(raw);
    return StaffSummary(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      employeeCode: json['employeeCode'] as String?,
      designationId: json['designationId'] as String?,
      classCategoryId: json['classCategoryId'] as String,
      mobile: Phone.fromJson(json['mobile']),
      isBlocked: json['isBlocked'] as bool,
    );
  }

  static List<StaffSummary> summaries(Object? raw) => [for (final item in jsonList(raw)) summary(item)];

  static Education _education(Object? raw) {
    final json = jsonObject(raw);
    return Education(
      degree: json['degree'] as String,
      qualification: json['qualification'] as String?,
      specialization: json['specialization'] as String?,
      institutionName: json['institutionName'] as String?,
      yearOfPassing: (json['yearOfPassing'] as num?)?.toInt(),
    );
  }

  static EmergencyContact _contact(Object? raw) {
    final json = jsonObject(raw);
    return EmergencyContact(
      contactName: json['contactName'] as String,
      relation: json['relation'] as String?,
      phone: Phone.fromJson(json['phone']),
      alternateNumber: json['alternateNumber'] as String?,
      isPrimary: json['isPrimary'] as bool,
    );
  }

  static StaffMember member(Object? raw) {
    final json = jsonObject(raw);
    final address = jsonObject(json['address']);
    return StaffMember(
      id: json['id'] as String,
      homeInstitutionId: json['homeInstitutionId'] as String,
      email: jsonObject(json['person'])['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      employeeCode: json['employeeCode'] as String?,
      gender: Gender.fromCode(json['gender']),
      dateOfBirth: json['dateOfBirth'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      nationality: json['nationality'] as String?,
      photoFileId: json['photoFileId'] as String?,
      designationId: json['designationId'] as String?,
      classCategoryId: json['classCategoryId'] as String,
      mobile: Phone.fromJson(json['mobile']),
      alternateNumber: json['alternateNumber'] as String?,
      address: StaffAddress(
        line1: address['line1'] as String?,
        line2: address['line2'] as String?,
        countryId: address['countryId'] as String?,
        stateId: address['stateId'] as String?,
        cityId: address['cityId'] as String?,
        pincode: address['pincode'] as String?,
      ),
      joiningDate: json['joiningDate'] as String?,
      resignationDate: json['resignationDate'] as String?,
      employmentType: EmploymentType.fromCode(json['employmentType']),
      educations: [for (final item in jsonList(json['educations'])) _education(item)],
      emergencyContacts: [for (final item in jsonList(json['emergencyContacts'])) _contact(item)],
      isBlocked: json['isBlocked'] as bool,
      version: (json['version'] as num).toInt(),
    );
  }
}
