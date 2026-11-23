import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/attendance_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

ApiFailure _code(String code, {int status = 422}) => ApiFailure(statusCode: status, code: code, message: 'x');

void main() {
  late AppLocalizations l10n;
  setUp(() => l10n = AppLocalizationsEn());

  test('attendanceErrorText has its own words for every code the roll and the actions can be refused with', () {
    final expected = {
      'NOT_ASSIGNED': l10n.errorAttendanceNotAssigned,
      'CURRENT_YEAR_REQUIRED': l10n.errorAttendanceNoYear,
      'DATE_IN_FUTURE': l10n.errorAttendanceFuture,
      'DATE_OUTSIDE_CURRENT_YEAR': l10n.errorAttendanceOutsideYear,
      'DATE_IS_HOLIDAY': l10n.errorAttendanceHoliday,
      'ATTENDANCE_ALREADY_SUBMITTED': l10n.errorAttendanceTaken,
      'ROSTER_CHANGED': l10n.errorAttendanceRosterChanged,
      'STUDENT_NOT_IN_SECTION': l10n.errorAttendanceNotInSection,
      'VERSION_CONFLICT': l10n.errorAttendanceVersion,
      'SESSION_VOIDED': l10n.errorAttendanceVoided,
    };
    for (final MapEntry(:key, :value) in expected.entries) {
      expect(attendanceErrorText(l10n, _code(key)), value, reason: key);
    }
    // Each is its own: none is the generic text a code without any would get.
    expect(expected.values.toSet(), hasLength(expected.length));
  });

  test('a 404 is a section that could not be found, and the rest reads as everywhere else', () {
    expect(attendanceErrorText(l10n, _code('NOT_FOUND', status: 404)), l10n.errorAttendanceNotFound);
    expect(attendanceErrorText(l10n, _code('FORBIDDEN', status: 403)), l10n.errorForbidden);
  });

  test('a correction refused as 403 FORBIDDEN is an earlier year, which only an Owner or an Admin may correct', () {
    expect(attendanceActionErrorText(l10n, _code('FORBIDDEN', status: 403)), l10n.errorAttendanceOlderYear);
    expect(attendanceActionErrorText(l10n, _code('ROSTER_CHANGED')), l10n.errorAttendanceRosterChanged);
  });
}
