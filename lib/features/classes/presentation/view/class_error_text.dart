import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes CLS-01 to CLS-05 can return (API design 10.4j): 400 VALIDATION_FAILED (and TOO_LONG, TOO_FEW,
/// TOO_MANY), 409 DUPLICATE, VERSION_CONFLICT and HAS_STUDENTS, 422 CLASS_NOT_OFFERED, STREAM_NOT_ALLOWED and
/// REFERENCE_INACTIVE, and 404 for a class already deactivated; the rest reads as everywhere else.
String classErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'VALIDATION_FAILED' || 'TOO_LONG' => l10n.errorValidation,
  'TOO_FEW' => l10n.errorClassTooFew,
  'TOO_MANY' => l10n.errorClassTooMany,
  'DUPLICATE' => l10n.errorClassDuplicate,
  'CLASS_NOT_OFFERED' => l10n.errorClassNotOffered,
  'STREAM_NOT_ALLOWED' => l10n.errorStreamNotAllowed,
  'REFERENCE_INACTIVE' => l10n.errorReferenceInactive,
  'VERSION_CONFLICT' => l10n.errorVersionConflict,
  'HAS_STUDENTS' => l10n.errorClassHasStudents,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorClassNotFound),
};

/// What to say under [field] for a refusal that names it, or null when it does not. A taken name, a taken class and the
/// two 422 refusals are said in the app's words; the rest keep the words the server gave.
String? classFieldError(AppLocalizations l10n, ApiFailure failure, String field) {
  final error = failure.fieldError(field);
  if (error == null) return null;
  return switch (error.code) {
    'DUPLICATE' => field == 'displayName' ? l10n.errorClassNameTaken : l10n.errorClassTaken,
    'CLASS_NOT_OFFERED' => l10n.errorClassNotOffered,
    'STREAM_NOT_ALLOWED' => l10n.errorStreamNotAllowed,
    'REFERENCE_INACTIVE' => l10n.errorReferenceInactive,
    _ => error.message,
  };
}
