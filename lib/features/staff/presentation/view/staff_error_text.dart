import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes STF-01 to STF-05 add (API design 10.5): 409 CANNOT_ACT_ON_SELF for the caller's own record on
/// Deactivate, and 404 for a staff member outside the caller's scope or already deactivated; the rest reads as
/// everywhere else.
String staffErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'CANNOT_ACT_ON_SELF' => l10n.errorCannotActOnSelf,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorStaffNotFound),
};
