import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes INS-01, INS-03 and INS-05 can return (API design 10.4c): 403 for a role that may not do
/// this, 404 for an Institution outside the caller's scope or already deactivated; the rest reads as everywhere else.
String institutionErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'FORBIDDEN' => l10n.errorForbidden,
  'NOT_FOUND' => l10n.errorInstitutionNotFound,
  _ => roleErrorText(l10n, failure),
};
