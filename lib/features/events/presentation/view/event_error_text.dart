import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/field_error_text.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for what EVT-02 to EVT-05 refuse with beyond the common codes: 403 SCOPE_NOT_ALLOWED (an Admin and an event of the
/// whole Society), and 404 for an event that is already gone; the rest reads as everywhere else.
String eventErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'SCOPE_NOT_ALLOWED' => l10n.errorEventScopeNotAllowed,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorEventNotFound),
};

/// What to say under [field] for a refusal that names it, or null when it does not: an end before the start, a holiday
/// for nobody and a class or Institution closed meanwhile are said in the app's words; the rest keep the server's.
String? eventFieldError(AppLocalizations l10n, ApiFailure failure, String field) {
  final error = failure.fieldError(field);
  if (error == null) return null;
  return switch ((field, error.code)) {
    ('endDate', 'OUT_OF_RANGE') => l10n.errorEventEndBeforeStart,
    ('holidayForStudents', FieldError.requiredCode) => l10n.errorEventHolidayWho,
    (_, 'REFERENCE_INACTIVE') => l10n.errorReferenceInactive,
    _ => fieldErrorText(l10n, error),
  };
}
