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
  _ => apiErrorText(l10n, failure, notFound: l10n.errorStaffNotFound),
};
