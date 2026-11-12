import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/student_draft.dart';

/// JSON → domain for STU-01 and STU-02, and the body of STU-02. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class StudentModels {
  static StudentPlacement _placement(Object? raw) {
    final json = jsonObject(raw);
    return StudentPlacement(
      academicYearId: json['academicYearId'] as String,
      classId: json['classId'] as String,
      sectionId: json['sectionId'] as String,
      rollNumber: json['rollNumber'] as String,
      startDate: json['startDate'] as String,
    );
  }

  static StudentSummary summary(Object? raw) {
    final json = jsonObject(raw);
    return StudentSummary(
      id: json['id'] as String,
      institutionId: json['institutionId'] as String,
      admissionNo: json['admissionNo'] as String?,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      photoFileId: json['photoFileId'] as String?,
      placement: _placement(json['placement']),
      isBlocked: json['isBlocked'] as bool,
      version: (json['version'] as num).toInt(),
    );
  }

  static List<StudentSummary> summaries(Object? raw) => [for (final item in jsonList(raw)) summary(item)];

  /// A student as STU-02 answers: who it is; the rest is read when a screen needs it.
  static Student student(Object? raw) {
    final json = jsonObject(raw);
    return Student(
      id: json['id'] as String,
      institutionId: json['institutionId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
    );
  }

  /// STU-02: what is set is sent; what is empty is left out. The numbers go in `identity` only when one is given.
  static Map<String, Object?> createBody(
    String institutionId,
    StudentDraft draft,
    EnrolmentDraft enrolment,
    List<GuardianDraft> guardians,
    IdentityDraft identity,
  ) => {
    'institutionId': institutionId,
    ..._details(draft),
    if (draft.admissionDate != null) 'admissionDate': draft.admissionDate,
    'enrolment': {
      'academicYearId': enrolment.academicYearId,
      'classId': enrolment.classId,
      'sectionId': enrolment.sectionId,
      'rollNumber': enrolment.rollNumber,
    },
    'guardians': [for (final guardian in guardians) _guardian(guardian)],
    if (!identity.isEmpty)
      'identity': {
        if (identity.aadhaarNumber != null) 'aadhaarNumber': identity.aadhaarNumber,
        if (identity.birthCertificateNumber != null) 'birthCertificateNumber': identity.birthCertificateNumber,
      },
  };

  static Map<String, Object?> _details(StudentDraft draft) {
    final address = draft.address;
    return {
      'firstName': draft.firstName,
      'mobile': draft.mobile.toJson(),
      for (final entry in {
        'lastName': draft.lastName,
        'gender': draft.gender?.code,
        'dateOfBirth': draft.dateOfBirth,
        'bloodGroup': draft.bloodGroup,
        'nationality': draft.nationality,
        'admissionNo': draft.admissionNo,
        'contactEmail': draft.contactEmail,
        'alternateNumber': draft.alternateNumber,
      }.entries)
        if (entry.value != null) entry.key: entry.value,
      if (draft.photoFileId != null) 'photoFileId': draft.photoFileId,
      if (!address.isEmpty) 'address': address.toJson(clearing: false),
    };
  }

  static Map<String, Object?> _guardian(GuardianDraft guardian) => {
    'firstName': guardian.firstName,
    'phone': guardian.phone.toJson(),
    'isPrimary': guardian.isPrimary,
    'isEmergencyContact': guardian.isEmergencyContact,
    if (guardian.relation != null) 'relation': guardian.relation!.code,
    if (guardian.lastName != null) 'lastName': guardian.lastName,
    if (guardian.alternatePhone != null) 'alternatePhone': guardian.alternatePhone,
    if (guardian.email != null) 'email': guardian.email,
    if (guardian.occupation != null) 'occupation': guardian.occupation,
  };
}
