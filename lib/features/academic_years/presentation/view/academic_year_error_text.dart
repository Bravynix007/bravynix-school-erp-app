import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes AY-01 to AY-05 add (API design 10.4h): 409 DUPLICATE (the name), YEAR_OVERLAP and
/// CURRENT_YEAR_LOCKED, and 404 for a year outside the caller's scope or already deactivated; the rest reads as
/// everywhere else.
String academicYearErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'DUPLICATE' => l10n.errorYearDuplicate,
  'YEAR_OVERLAP' => l10n.errorYearOverlap,
  'CURRENT_YEAR_LOCKED' => l10n.errorCurrentYearLocked,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorYearNotFound),
};

/// What to say under [field] (`name`, `startDate` or `endDate`) for a refusal that names it, or null when it does not.
/// A taken name is said in the app's words; the rest keep the words the server gave.
String? academicYearFieldError(AppLocalizations l10n, ApiFailure failure, String field) {
  final error = failure.fieldError(field);
  if (error == null) return null;
  return error.code == 'DUPLICATE' ? l10n.errorYearDuplicate : error.message;
}
