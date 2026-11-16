import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes the stars add (API design 10.5d): 403 NOT_ASSIGNED for a student outside the teacher's sections,
/// 422 NO_CURRENT_PLACEMENT for a student who sits in no section now, and 404 for a student or a star that is not found.
/// The rest reads as everywhere else, FORBIDDEN among it.
String achievementErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'NOT_ASSIGNED' => l10n.errorNotAssigned,
  'NO_CURRENT_PLACEMENT' => l10n.errorNoCurrentPlacement,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorAchievementNotFound),
};
