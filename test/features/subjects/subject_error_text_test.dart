import 'dart:ui';

import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/view/subject_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  String text(int status, String code) =>
      subjectErrorText(l10n, ApiFailure(statusCode: status, code: code, message: 'server words'));

  test("says in the app's own words what each refusal of the subject endpoints means", () {
    expect(text(400, 'VALIDATION_FAILED'), 'Check the fields marked in red.');
    expect(text(409, 'DUPLICATE'), 'Another subject has this name or code.');
    expect(text(409, 'VERSION_CONFLICT'), 'Someone else changed this. Your changes were not saved.');
    expect(text(404, 'NOT_FOUND'), 'This subject could not be found. It may have been deactivated.');
    expect(text(403, 'FORBIDDEN'), "You don't have access to this.");
  });

  group('under a field', () {
    ApiFailure failure(String code) => ApiFailure(
      statusCode: 409,
      code: 'DUPLICATE',
      message: 'm',
      fieldErrors: [FieldError(field: 'name', code: code, message: 'Server words')],
    );

    test('a taken name or code is said in the app words', () {
      expect(subjectFieldError(l10n, failure('DUPLICATE'), 'name'), 'Another subject has this name.');
      const code = ApiFailure(
        statusCode: 409,
        code: 'DUPLICATE',
        message: 'm',
        fieldErrors: [FieldError(field: 'code', code: 'DUPLICATE', message: 'x')],
      );
      expect(subjectFieldError(l10n, code, 'code'), 'Another subject has this code.');
    });

    test('any other refusal of the field keeps the words the server gave', () {
      expect(subjectFieldError(l10n, failure('TOO_LONG'), 'name'), 'Server words');
    });

    test('a field the refusal does not name has nothing to say', () {
      expect(subjectFieldError(l10n, failure('DUPLICATE'), 'code'), isNull);
    });
  });
}
