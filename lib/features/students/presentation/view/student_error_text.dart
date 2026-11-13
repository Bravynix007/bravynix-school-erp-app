import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes STU-01 and STU-05 add (API design 10.5): 404 for a student outside the caller's scope or already
/// deactivated. The rest reads as everywhere else.
String studentErrorText(AppLocalizations l10n, ApiFailure failure) =>
    apiErrorText(l10n, failure, notFound: l10n.errorStudentNotFound);

/// Copy for the codes STU-02 adds (API design 10.6): 409 ADMISSION_NO_TAKEN, ROLL_NUMBER_TAKEN,
/// AADHAAR_DUPLICATE_IN_INSTITUTION and ROLE_CONFLICT (a guardian's email that is a platform account); 422
/// SECTION_NOT_IN_CLASS, YEAR_NOT_ACTIVE, INACTIVE_SECTION, INVALID_AADHAAR, PRIMARY_GUARDIAN_REQUIRED and
/// REFERENCE_INACTIVE (a photo that is no longer available); and 404 for an Institution, year, class, section or photo
/// that is not found. STU-12 adds 422 TARGET_CLASS_BELOW_SOURCE, CLASS_UNCHANGED and NO_CURRENT_PLACEMENT. The rest
/// reads as everywhere else, ACCOUNT_BLOCKED among it. [notFound] words a 404 that is not
/// about those, such as a student deactivated meanwhile.
String studentFormErrorText(AppLocalizations l10n, ApiFailure failure, {String? notFound}) => switch (failure.code) {
  'ADMISSION_NO_TAKEN' => l10n.errorAdmissionNoTaken,
  'ROLL_NUMBER_TAKEN' => l10n.errorRollNumberTaken,
  'AADHAAR_DUPLICATE_IN_INSTITUTION' => l10n.errorAadhaarDuplicateInInstitution,
  'ROLE_CONFLICT' => l10n.errorGuardianRoleConflict,
  'SECTION_NOT_IN_CLASS' => l10n.errorSectionNotInClass,
  'YEAR_NOT_ACTIVE' => l10n.errorStudentYearNotActive,
  'INACTIVE_SECTION' => l10n.errorInactiveSection,
  'INVALID_AADHAAR' => l10n.errorAadhaarInvalid,
  'PRIMARY_GUARDIAN_REQUIRED' => l10n.errorPrimaryGuardianRequired,
  'REFERENCE_INACTIVE' => l10n.errorReferenceInactive,
  'TARGET_CLASS_BELOW_SOURCE' => l10n.errorTargetClassBelowSource,
  'CLASS_UNCHANGED' => l10n.errorClassUnchanged,
  'NO_CURRENT_PLACEMENT' => l10n.errorNoCurrentPlacement,
  _ => apiErrorText(l10n, failure, notFound: notFound ?? l10n.errorStudentFormNotFound),
};
