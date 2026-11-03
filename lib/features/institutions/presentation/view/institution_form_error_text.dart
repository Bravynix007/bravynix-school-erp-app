import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes INS-02 and INS-04 add to those every Institution screen can return (API design 10.4c): 409
/// DUPLICATE (the code) and CATEGORY_IN_USE, and 422 REFERENCE_INACTIVE.
String institutionFormErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'DUPLICATE' => l10n.errorInstitutionDuplicate,
  'CATEGORY_IN_USE' => l10n.errorCategoryInUse,
  'REFERENCE_INACTIVE' => l10n.errorReferenceInactive,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorInstitutionNotFound),
};
