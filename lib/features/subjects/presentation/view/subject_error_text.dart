import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes SUB-01 to SUB-04 add (API design 10.4i): 409 DUPLICATE (the name or the code, which
/// [subjectFieldError] says under the field), and 404 for a subject that was already deactivated; the rest reads as
/// everywhere else.
String subjectErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'DUPLICATE' => l10n.errorSubjectDuplicate,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorSubjectNotFound),
};

/// What to say under [field] (`name` or `code`) for a refusal that names it, or null when it does not.
String? subjectFieldError(AppLocalizations l10n, ApiFailure failure, String field) {
  final error = failure.fieldError(field);
  if (error == null) return null;
  if (error.code == 'DUPLICATE') return field == 'name' ? l10n.errorSubjectNameTaken : l10n.errorSubjectCodeTaken;
  return error.message;
}
