import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/login_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes AUTH-06 adds (API design 10.4); the rest reads as in login.
String roleErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'CONTEXT_NOT_AVAILABLE' => l10n.errorContextNotAvailable,
  'ACCESS_BLOCKED' => l10n.errorAccessBlocked,
  // 423 (API design 6.5): `details.section` says which group is blocked; Owners are told to ask BravyNix.
  'SECTION_BLOCKED' =>
    failure.details['section'] == 'owners' ? l10n.errorSectionBlockedOwners : l10n.errorSectionBlocked,
  _ => loginErrorText(l10n, failure),
};

/// Copy for a screen that reads or changes one kind of record (API design 10.4c, 10.22): 403 for a role that may not
/// do this, 404 with the screen's own words for [notFound] (an Institution or a due outside the caller's scope), and
/// the rest as everywhere else.
String apiErrorText(AppLocalizations l10n, ApiFailure failure, {required String notFound}) => switch (failure.code) {
  'FORBIDDEN' => l10n.errorForbidden,
  'NOT_FOUND' => notFound,
  _ => roleErrorText(l10n, failure),
};
