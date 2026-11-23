import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Copy for the codes ATT-01, ATT-02, ATT-05 and ATT-06 add (API design 10.10 to 10.12a): 404 for a section out of
/// reach and 403 NOT_ASSIGNED for a teacher away from their own Institution; 422 CURRENT_YEAR_REQUIRED, DATE_IN_FUTURE, DATE_OUTSIDE_CURRENT_YEAR, DATE_IS_HOLIDAY and
/// STUDENT_NOT_IN_SECTION; 409 ATTENDANCE_ALREADY_SUBMITTED, ROSTER_CHANGED, VERSION_CONFLICT and SESSION_VOIDED. The rest
/// reads as everywhere else.
String attendanceErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'NOT_ASSIGNED' => l10n.errorAttendanceNotAssigned,
  'CURRENT_YEAR_REQUIRED' => l10n.errorAttendanceNoYear,
  'DATE_IN_FUTURE' => l10n.errorAttendanceFuture,
  'DATE_OUTSIDE_CURRENT_YEAR' => l10n.errorAttendanceOutsideYear,
  'DATE_IS_HOLIDAY' => l10n.errorAttendanceHoliday,
  'ATTENDANCE_ALREADY_SUBMITTED' => l10n.errorAttendanceTaken,
  'ROSTER_CHANGED' => l10n.errorAttendanceRosterChanged,
  'STUDENT_NOT_IN_SECTION' => l10n.errorAttendanceNotInSection,
  'VERSION_CONFLICT' => l10n.errorAttendanceVersion,
  'SESSION_VOIDED' => l10n.errorAttendanceVoided,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorAttendanceNotFound),
};

/// Copy for a refusal of an action on the roll (ATT-02, ATT-05, ATT-06): as for the roll, except that 403 FORBIDDEN here
/// is a teacher correcting a register of an earlier year, which only an Owner or an Admin may.
String attendanceActionErrorText(AppLocalizations l10n, ApiFailure failure) =>
    failure.code == 'FORBIDDEN' ? l10n.errorAttendanceOlderYear : attendanceErrorText(l10n, failure);

/// Copy for the codes ATT-07 and ATT-08 add (API design 10.13): 422 OUTSIDE_ACADEMIC_YEAR for a month or day no year of
/// the Institution holds, 403 NOT_ASSIGNED for a teacher and a student outside their sections, 404 for a student out of
/// reach, and 403 CHILD_ACCESS_BLOCKED for a blocked child. The rest reads as everywhere else.
String attendanceCalendarErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'OUTSIDE_ACADEMIC_YEAR' => l10n.errorAttendanceCalendarOutsideYear,
  'NOT_ASSIGNED' => l10n.errorAttendanceCalendarNotAssigned,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorAttendanceCalendarNotFound),
};
