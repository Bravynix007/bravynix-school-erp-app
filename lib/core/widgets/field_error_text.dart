import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// What to say under a field the API (or the form itself) found wrong: the copy for the codes a form can raise
/// before sending anything, else the server's own words.
String fieldErrorText(AppLocalizations l10n, FieldError error) => switch (error.code) {
  FieldError.requiredCode => l10n.errorFieldRequired,
  'INVALID_AADHAAR' => l10n.errorAadhaarInvalid,
  _ => error.message,
};
