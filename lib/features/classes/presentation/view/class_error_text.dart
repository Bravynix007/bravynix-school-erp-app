import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes CLS-01 to CLS-05 add (API design 10.4j): 409 DUPLICATE and HAS_STUDENTS, 422 CLASS_NOT_OFFERED,
/// STREAM_NOT_ALLOWED and REFERENCE_INACTIVE, and 404 for a class already deactivated; the rest reads as everywhere
/// else. TOO_LONG, TOO_FEW and TOO_MANY come only as field codes inside 400 VALIDATION_FAILED, and the app cannot send
/// what they refuse.
String classErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'DUPLICATE' => l10n.errorClassDuplicate,
  'CLASS_NOT_OFFERED' => l10n.errorClassNotOffered,
  'STREAM_NOT_ALLOWED' => l10n.errorStreamNotAllowed,
  'REFERENCE_INACTIVE' => l10n.errorReferenceInactive,
  'HAS_STUDENTS' => l10n.errorClassHasStudents,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorClassNotFound),
};

final _item = RegExp(r'^classes\[(\d+)\]\.');

/// What Add several says about a refusal. All or nothing, and a refusal that names an item (`classes[1].displayName`) is
/// said with that class's name, so the person knows which ticked class to untick; [names] are the names of the classes
/// sent, in order. Any other refusal reads as [classErrorText].
String classBulkErrorText(AppLocalizations l10n, ApiFailure failure, List<String> names) {
  for (final error in failure.fieldErrors) {
    final index = int.tryParse(_item.firstMatch(error.field)?.group(1) ?? '');
    if (index != null && index < names.length) {
      return l10n.classBulkItemRefused(names[index], classFieldError(l10n, failure, error.field)!);
    }
  }
  return classErrorText(l10n, failure);
}

/// What to say under [field] for a refusal that names it, or null when it does not. A taken name, a taken class and the
/// two 422 refusals are said in the app's words; the rest keep the words the server gave.
String? classFieldError(AppLocalizations l10n, ApiFailure failure, String field) {
  final error = failure.fieldError(field);
  if (error == null) return null;
  return switch (error.code) {
    'DUPLICATE' => field.endsWith('displayName') ? l10n.errorClassNameTaken : l10n.errorClassTaken,
    'CLASS_NOT_OFFERED' => l10n.errorClassNotOffered,
    'STREAM_NOT_ALLOWED' => l10n.errorStreamNotAllowed,
    'REFERENCE_INACTIVE' => l10n.errorReferenceInactive,
    _ => error.message,
  };
}
