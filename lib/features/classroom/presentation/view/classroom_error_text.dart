import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the classroom view (API design 6.4 D7, 10.4j): 403 `NOT_ASSIGNED` for a student outside the teacher's own
/// sections, 404 for a student of an Institution they do not reach. The rest reads as everywhere else.
String classroomErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'NOT_ASSIGNED' => l10n.errorNotAssigned,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorStudentProfileNotFound),
};
