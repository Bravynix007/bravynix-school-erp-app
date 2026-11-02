import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes BIL-01 and BIL-02 can return (API design 10.22): 403 for a role that is not an Owner, 404
/// for a due that is not this Society's; the rest reads as everywhere else.
String dueErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'FORBIDDEN' => l10n.errorForbidden,
  'NOT_FOUND' => l10n.errorDueNotFound,
  _ => roleErrorText(l10n, failure),
};
