import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes DIA-01 adds (API design 10.14a): 403 NOT_ASSIGNED (a teacher reads only a section they lead or
/// teach), 422 CURRENT_YEAR_REQUIRED, and 404 for a section out of reach or a child that is not the parent's; the rest,
/// a blocked child included, reads as everywhere else.
String diaryErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'NOT_ASSIGNED' => l10n.errorDiaryNotAssigned,
  'CURRENT_YEAR_REQUIRED' => l10n.errorDiaryNoYear,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorDiaryNotFound),
};

/// Copy for the codes DIA-02 to DIA-04 add: 403 NOT_ASSIGNED (the subject or section is not theirs to write for, or the
/// entry is another teacher's), the three dates 422 DATE_IN_FUTURE, DATE_TOO_OLD and DATE_OUTSIDE_CURRENT_YEAR, and a
/// 404 for an entry already removed; the rest reads as for the list. [adding] is DIA-02, as against a change or a delete.
String diaryEntryErrorText(AppLocalizations l10n, ApiFailure failure, {required bool adding}) => switch (failure.code) {
  'NOT_ASSIGNED' => adding ? l10n.errorDiaryNotAssignedAdd : l10n.errorDiaryNotAssignedChange,
  'DATE_IN_FUTURE' => l10n.errorDiaryFuture,
  'DATE_TOO_OLD' => l10n.errorDiaryTooOld,
  'DATE_OUTSIDE_CURRENT_YEAR' => l10n.errorDiaryOutsideYear,
  'REFERENCE_INACTIVE' => l10n.errorReferenceInactive,
  'NOT_FOUND' when !adding => l10n.errorDiaryEntryGone,
  _ => diaryErrorText(l10n, failure),
};
