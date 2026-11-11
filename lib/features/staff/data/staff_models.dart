import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_draft.dart';
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
      subjectIds: [for (final id in jsonList(json['subjectIds'])) id as String],
      institutionIds: [for (final id in jsonList(json['institutionIds'])) id as String],
    );
  }

  /// STF-02: what is set is sent; what is empty is left out.
  static Map<String, Object?> createBody(String institutionId, StaffDraft draft) => {
    'homeInstitutionId': institutionId,
    'email': draft.email,
    ..._profile(draft, clearing: false),
  };

  /// STF-04: every editable field, with `null` for what the form left empty, so clearing a field clears it. The two
  /// lists are replaced as a whole. The email is never sent, and the photo only when a new one was uploaded.
  static Map<String, Object?> updateBody(StaffDraft draft, int version) => {
    'version': version,
    ..._profile(draft, clearing: true),
  };

  static Map<String, Object?> _profile(StaffDraft draft, {required bool clearing}) {
    Map<String, Object?> optional(Map<String, Object?> fields) => {
      for (final entry in fields.entries)
        if (clearing || entry.value != null) entry.key: entry.value,
    };
    final address = draft.address;
    return {
      'firstName': draft.firstName,
      'classCategoryId': draft.classCategoryId,
      'mobile': draft.mobile.toJson(),
      ...optional({
        'lastName': draft.lastName,
        'employeeCode': draft.employeeCode,
        'gender': draft.gender?.code,
        'dateOfBirth': draft.dateOfBirth,
        'bloodGroup': draft.bloodGroup,
        'nationality': draft.nationality,
        'designationId': draft.designationId,
        'alternateNumber': draft.alternateNumber,
        'joiningDate': draft.joiningDate,
        'resignationDate': draft.resignationDate,
        'employmentType': draft.employmentType?.code,
      }),
      // A photo is never cleared here: no photo chosen leaves the one the record has.
      if (draft.photoFileId != null) 'photoFileId': draft.photoFileId,
      if (clearing || !address.isEmpty)
        'address': optional({
          'line1': address.line1,
          'line2': address.line2,
          'countryId': address.countryId,
          'stateId': address.stateId,
          'cityId': address.cityId,
          'pincode': address.pincode,
        }),
      'educations': [
        for (final line in draft.educations)
          {
            'degree': line.degree,
            ...optional({
              'qualification': line.qualification,
              'specialization': line.specialization,
              'institutionName': line.institutionName,
              'yearOfPassing': line.yearOfPassing,
            }),
          },
      ],
      'emergencyContacts': [
        for (final contact in draft.emergencyContacts)
          {
            'contactName': contact.contactName,
            'phone': contact.phone.toJson(),
            'isPrimary': contact.isPrimary,
            ...optional({'relation': contact.relation, 'alternateNumber': contact.alternateNumber}),
          },
      ],
    };
  }
}
