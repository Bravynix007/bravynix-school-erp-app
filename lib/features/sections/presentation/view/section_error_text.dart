import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes SEC-01 to SEC-04 can return (API design 10.4j): 400 VALIDATION_FAILED (and TOO_LONG), 409
/// DUPLICATE, VERSION_CONFLICT and HAS_STUDENTS, 422 REFERENCE_INACTIVE, and 404 for a class or section already
/// deactivated; the rest reads as everywhere else.
String sectionErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'VALIDATION_FAILED' || 'TOO_LONG' => l10n.errorValidation,
  'DUPLICATE' => l10n.errorSectionDuplicate,
  'REFERENCE_INACTIVE' => l10n.errorReferenceInactive,
  'VERSION_CONFLICT' => l10n.errorVersionConflict,
  'HAS_STUDENTS' => l10n.errorSectionHasStudents,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorSectionNotFound),
};

/// What to say under [field] for a refusal that names it, or null when it does not. A taken section and a taken name
/// are said in the app's words; the rest keep the words the server gave.
String? sectionFieldError(AppLocalizations l10n, ApiFailure failure, String field) {
  final error = failure.fieldError(field);
  if (error == null) return null;
  return switch (error.code) {
    'DUPLICATE' => field == 'displayName' ? l10n.errorSectionNameTaken : l10n.errorSectionTaken,
    'REFERENCE_INACTIVE' => l10n.errorReferenceInactive,
    _ => error.message,
  };
}
