import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

ApiFailure _code(String code, {int status = 422}) => ApiFailure(statusCode: status, code: code, message: 'x');

void main() {
  testWidgets('studentFormErrorText has its own words for every code a student form can be refused with', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpApp(
      Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox();
        },
      ),
    );
    final expected = {
      'ADMISSION_NO_TAKEN': l10n.errorAdmissionNoTaken,
      'ROLL_NUMBER_TAKEN': l10n.errorRollNumberTaken,
      'AADHAAR_DUPLICATE_IN_INSTITUTION': l10n.errorAadhaarDuplicateInInstitution,
      'ROLE_CONFLICT': l10n.errorGuardianRoleConflict,
      'SECTION_NOT_IN_CLASS': l10n.errorSectionNotInClass,
      'YEAR_NOT_ACTIVE': l10n.errorStudentYearNotActive,
      'INACTIVE_SECTION': l10n.errorInactiveSection,
      'INVALID_AADHAAR': l10n.errorAadhaarInvalid,
      'PRIMARY_GUARDIAN_REQUIRED': l10n.errorPrimaryGuardianRequired,
      'REFERENCE_INACTIVE': l10n.errorReferenceInactive,
      'TARGET_CLASS_BELOW_SOURCE': l10n.errorTargetClassBelowSource,
      'CLASS_UNCHANGED': l10n.errorClassUnchanged,
      'NO_CURRENT_PLACEMENT': l10n.errorNoCurrentPlacement,
    };
    for (final MapEntry(:key, :value) in expected.entries) {
      expect(studentFormErrorText(l10n, _code(key)), value, reason: key);
    }
    // Each of the words is its own: none is the generic text a code without any would get.
    expect(expected.values.toSet(), hasLength(expected.length));
    expect(studentFormErrorText(l10n, _code('NOT_FOUND', status: 404)), l10n.errorStudentFormNotFound);
    // STU-08: a move over a day the old register was taken names the latest such day, as the API gives it.
    expect(
      studentFormErrorText(
        l10n,
        const ApiFailure(
          statusCode: 409,
          code: 'ATTENDANCE_TAKEN',
          message: 'x',
          details: {'attendanceDate': '2026-11-17'},
        ),
      ),
      l10n.errorStudentMoveAttendanceTaken('17-11-2026'),
    );
    for (final details in [
      <String, dynamic>{},
      {'attendanceDate': 'soon'},
      {'attendanceDate': 7},
    ]) {
      expect(
        studentFormErrorText(
          l10n,
          ApiFailure(statusCode: 409, code: 'ATTENDANCE_TAKEN', message: 'x', details: details),
        ),
        l10n.errorStudentMoveAttendanceTakenNoDay,
        reason: '$details',
      );
    }
    // An edit (STU-04) is also refused when the student was changed meanwhile, or is gone.
    expect(studentFormErrorText(l10n, _code('VERSION_CONFLICT', status: 409)), l10n.errorVersionConflict);
    expect(
      studentFormErrorText(l10n, _code('NOT_FOUND', status: 404), notFound: l10n.errorStudentNotFound),
      l10n.errorStudentNotFound,
    );
  });

  testWidgets('studentIdentityErrorText has its own words for the codes of the identity numbers', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpApp(
      Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox();
        },
      ),
    );
    final expected = {
      'INVALID_AADHAAR': l10n.errorAadhaarInvalid,
      'AADHAAR_DUPLICATE_IN_INSTITUTION': l10n.errorAadhaarDuplicateInInstitution,
      'NOT_SET': l10n.errorAadhaarNotSet,
      'REVEAL_LIMIT': l10n.errorRevealLimit,
    };
    for (final MapEntry(:key, :value) in expected.entries) {
      expect(studentIdentityErrorText(l10n, _code(key)), value, reason: key);
    }
    expect(studentIdentityErrorText(l10n, _code('NOT_FOUND', status: 404)), l10n.errorStudentNotFound);
  });

  testWidgets('promotionErrorText has its own words for the codes of a promotion', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpApp(
      Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox();
        },
      ),
    );
    final expected = {
      'TARGET_YEAR_NOT_AFTER_SOURCE': l10n.errorPromotionYearNotAfter,
      'TARGET_CLASS_BELOW_SOURCE': l10n.errorPromotionClassBelow,
      'NOT_FINAL_CLASS': l10n.errorPromotionNotFinalClass,
      'ALREADY_ENROLLED': l10n.errorPromotionAlreadyEnrolled,
      'BATCH_TOO_LARGE': l10n.errorPromotionTooLarge,
      'ROLL_NUMBER_TAKEN': l10n.errorRollNumberTaken,
      'SECTION_NOT_IN_CLASS': l10n.errorSectionNotInClass,
      'YEAR_NOT_ACTIVE': l10n.errorStudentYearNotActive,
      'INACTIVE_SECTION': l10n.errorInactiveSection,
      'NO_CURRENT_PLACEMENT': l10n.errorNoCurrentPlacement,
    };
    for (final MapEntry(:key, :value) in expected.entries) {
      expect(promotionErrorText(l10n, _code(key)), value, reason: key);
    }
    expect(expected.values.toSet(), hasLength(expected.length));
    expect(promotionErrorText(l10n, _code('NOT_FOUND', status: 404)), l10n.errorPromotionNotFound);
  });

  testWidgets(
    'studentImportErrorText has its own words for the codes of an import, and studentImportFailureText for a failed one',
    (
      tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      );
      final expected = {
        'FILE_NOT_READY': l10n.errorImportFileNotReady,
        'IMPORT_ALREADY_RUNNING': l10n.errorImportAlreadyRunning,
        'YEAR_NOT_ACTIVE': l10n.errorStudentYearNotActive,
      };
      for (final MapEntry(:key, :value) in expected.entries) {
        expect(studentImportErrorText(l10n, _code(key)), value, reason: key);
      }
      expect(studentImportErrorText(l10n, _code('NOT_FOUND', status: 404)), l10n.errorImportNotFound);
      final failures = {
        'CSV_HEADER_INVALID': l10n.errorImportHeaderInvalid,
        'CSV_TOO_LARGE': l10n.errorImportTooLarge,
        'CSV_UNREADABLE': l10n.errorImportUnreadable,
        'IMPORT_FAILED': l10n.errorImportFailed,
      };
      for (final MapEntry(:key, :value) in failures.entries) {
        expect(studentImportFailureText(l10n, key), value, reason: key);
      }
      expect({...expected.values, ...failures.values}, hasLength(expected.length + failures.length));
      // A code the app does not know reads as a failure of the import, not as nothing.
      expect(studentImportFailureText(l10n, 'SOMETHING_NEW'), l10n.errorImportFailed);
    },
  );
}
