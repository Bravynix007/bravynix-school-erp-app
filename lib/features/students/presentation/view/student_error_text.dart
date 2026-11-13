import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes STU-01 and STU-05 add (API design 10.5): 404 for a student outside the caller's scope or already
/// deactivated. The rest reads as everywhere else.
String studentErrorText(AppLocalizations l10n, ApiFailure failure) =>
    apiErrorText(l10n, failure, notFound: l10n.errorStudentNotFound);
