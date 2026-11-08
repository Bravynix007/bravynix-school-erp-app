import 'dart:ui';

import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/view/academic_year_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  String text(int status, String code) =>
      academicYearErrorText(l10n, ApiFailure(statusCode: status, code: code, message: 'server words'));

  test("says in the app's own words what each refusal of the academic year endpoints means", () {
    expect(text(400, 'VALIDATION_FAILED'), 'Check the fields marked in red.');
    expect(text(409, 'DUPLICATE'), 'Another academic year of this Institution has this name.');
    expect(text(409, 'YEAR_OVERLAP'), 'These dates overlap another academic year of this Institution.');
    expect(text(409, 'VERSION_CONFLICT'), 'Someone else changed this. Your changes were not saved.');
    expect(
      text(409, 'CURRENT_YEAR_LOCKED'),
      "The current year can't be deactivated. Make another year current first.",
    );
    expect(text(404, 'NOT_FOUND'), 'This academic year could not be found. It may have been deactivated.');
  });

  test('the rest read as everywhere else', () {
    expect(text(403, 'FORBIDDEN'), "You don't have access to this.");
  });

  group('under a field', () {
    ApiFailure failure(String code) => ApiFailure(
      statusCode: 409,
      code: 'DUPLICATE',
      message: 'm',
      fieldErrors: [FieldError(field: 'name', code: code, message: 'Server words')],
    );

    test('a taken name is said in the app words', () {
      expect(
        academicYearFieldError(l10n, failure('DUPLICATE'), 'name'),
        'Another academic year of this Institution has this name.',
      );
    });

    test('any other refusal of the field keeps the words the server gave', () {
      expect(academicYearFieldError(l10n, failure('TOO_LONG'), 'name'), 'Server words');
    });

    test('a field the refusal does not name has nothing to say', () {
      expect(academicYearFieldError(l10n, failure('DUPLICATE'), 'startDate'), isNull);
    });
  });
}
