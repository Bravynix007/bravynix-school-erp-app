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
  });
}
