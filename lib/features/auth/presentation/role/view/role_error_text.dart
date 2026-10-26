import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/login_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes AUTH-06 adds (API design 10.4); the rest reads as in login.
String roleErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'CONTEXT_NOT_AVAILABLE' => l10n.errorContextNotAvailable,
  'ACCESS_BLOCKED' => l10n.errorAccessBlocked,
  _ => loginErrorText(l10n, failure),
};
