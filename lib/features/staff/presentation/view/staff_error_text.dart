import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes STF-01 to STF-05 add (API design 10.5): 409 CANNOT_ACT_ON_SELF for the caller's own record on
/// Deactivate; 409 EMPLOYEE_ID_TAKEN, DUPLICATE (the person already has an active record) and ROLE_CONFLICT (a platform
/// account) when a staff member is added; 422 REFERENCE_INACTIVE for a category, designation, photo, subject or
/// Institution no longer available; 409 INVALID_STATE for a block or a lift the record is already in, SUBJECT_ASSIGNED
/// and ADMIN_ACCESS_HELD (API design 6.8) for a subject or an Institution that cannot be dropped yet; and 404 for a staff member outside the caller's scope or already deactivated. The rest reads as
/// everywhere else, ACCOUNT_BLOCKED among it.
String staffErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'CANNOT_ACT_ON_SELF' => l10n.errorCannotActOnSelf,
  'EMPLOYEE_ID_TAKEN' => l10n.errorEmployeeIdTaken,
  'DUPLICATE' => l10n.errorStaffDuplicate,
  'ROLE_CONFLICT' => l10n.errorRoleConflict,
  'REFERENCE_INACTIVE' => l10n.errorReferenceInactive,
  'INVALID_STATE' => l10n.errorStaffAccessState,
  'SUBJECT_ASSIGNED' => l10n.errorSubjectAssigned,
  'ADMIN_ACCESS_HELD' => l10n.errorAdminAccessHeld,
  'STAFF_BLOCKED' => l10n.errorStaffBlocked,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorStaffNotFound),
};

/// Copy for the codes INS-09 and INS-10 add (API design 10.5): 422 STAFF_BLOCKED for a blocked record, 422
/// STAFF_NOT_AT_INSTITUTION for an Institution that is neither their home nor one of their extra ones, 409 ALREADY_ADMIN,
/// and 409 INVALID_STATE for an account that cannot hold a role. A 404 on a take-away (INS-10) means there was no access
/// to take away; on a grant it means the staff member is gone. The rest reads as for the other staff calls.
String staffAdminErrorText(AppLocalizations l10n, ApiFailure failure, {bool takeAway = false}) =>
    switch (failure.code) {
      'NOT_FOUND' when takeAway => l10n.errorAdminNotHeld,
      'ALREADY_ADMIN' => l10n.errorAdminAlready,
      'STAFF_BLOCKED' => l10n.errorAdminStaffBlocked,
      'STAFF_NOT_AT_INSTITUTION' => l10n.errorAdminNotAtInstitution,
      'INVALID_STATE' => l10n.errorAdminAccountState,
      _ => staffErrorText(l10n, failure),
    };

/// Copy for the codes STF-09 adds (API design 10.5a): 409 CLASS_TEACHER_TAKEN when another teacher leads the section that
/// year, 422 STAFF_BLOCKED, 422 REFERENCE_INACTIVE for a year or section that is deactivated, and 404 for a staff member,
/// year or section that is not found. The rest reads as for the other staff calls.
String staffClassTeacherErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'CLASS_TEACHER_TAKEN' => l10n.errorClassTeacherTaken,
  'NOT_FOUND' => l10n.errorClassTeacherNotFound,
  _ => staffErrorText(l10n, failure),
};

/// Copy for the codes ASG-02 and ASG-03 add (API design 10.5a): 409 DUPLICATE when they already teach the subject in the
/// section that year, 422 SUBJECT_NOT_TAUGHT for a subject that is not on their list, 422 STAFF_BLOCKED, 422
/// REFERENCE_INACTIVE for a year, section or subject that is deactivated, and 404 for an assignment, section or subject
/// that is not found. The rest reads as for the other staff calls.
String staffTeachingErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'DUPLICATE' => l10n.errorTeachingDuplicate,
  'SUBJECT_NOT_TAUGHT' => l10n.errorSubjectNotTaught,
  'NOT_FOUND' => l10n.errorTeachingNotFound,
  _ => staffErrorText(l10n, failure),
};

/// Copy for the codes STF-11 and STF-12 add (API design 6.8, 10.9): 422 INVALID_AADHAAR, 409 AADHAAR_EXISTS_IN_SOCIETY
/// (without saying whose), 404 NOT_SET for a reveal when no number is held, and 429 REVEAL_LIMIT after ten reveals in
/// a day. The rest reads as for the other staff calls.
String staffIdentityErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'INVALID_AADHAAR' => l10n.errorAadhaarInvalid,
  'AADHAAR_EXISTS_IN_SOCIETY' => l10n.errorAadhaarExists,
  'NOT_SET' => l10n.errorAadhaarNotSet,
  'REVEAL_LIMIT' => l10n.errorRevealLimit,
  _ => staffErrorText(l10n, failure),
};
