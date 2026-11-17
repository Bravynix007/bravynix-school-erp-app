import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes TT-01 adds (API design 9.7): 403 NOT_ASSIGNED (a teacher reads only a section they lead or teach),
/// 422 CURRENT_YEAR_REQUIRED, and 404 for a section out of reach or a child that is not the parent's; the rest, a blocked
/// child included, reads as everywhere else.
String timetableErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'NOT_ASSIGNED' => l10n.errorTimetableNotAssigned,
  'CURRENT_YEAR_REQUIRED' => l10n.errorTimetableNoYear,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorTimetableNotFound),
};
