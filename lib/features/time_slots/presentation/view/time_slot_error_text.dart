import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/field_error_text.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes TTS-01 to TTS-04 add (API design 9.7): 409 DUPLICATE (the number), TIME_SLOT_OVERLAP and
/// TIME_SLOT_IN_USE, 422 CURRENT_YEAR_REQUIRED, and 404 for a period outside the caller's scope or already
/// deactivated; the rest reads as everywhere else.
String timeSlotErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'DUPLICATE' => l10n.errorTimeSlotDuplicate,
  'TIME_SLOT_OVERLAP' => l10n.errorTimeSlotOverlap,
  'TIME_SLOT_IN_USE' => l10n.errorTimeSlotInUse,
  'CURRENT_YEAR_REQUIRED' => l10n.errorCurrentYearRequired,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorTimeSlotNotFound),
};

/// What to say under [field] for a refusal that names it, or null when it does not. The number taken and the overlap
/// are said in the app's words; the rest (`OUT_OF_RANGE`, `INVALID_FORMAT`) keep the words the server gave.
String? timeSlotFieldError(AppLocalizations l10n, ApiFailure failure, String field) {
  final error = failure.fieldError(field);
  if (error == null) return null;
  return switch (error.code) {
    'DUPLICATE' => l10n.errorTimeSlotDuplicate,
    'TIME_SLOT_OVERLAP' => l10n.errorTimeSlotOverlap,
    _ => fieldErrorText(l10n, error),
  };
}
