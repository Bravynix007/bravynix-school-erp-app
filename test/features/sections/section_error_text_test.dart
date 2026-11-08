import 'dart:ui';

import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/section_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  String text(int status, String code) =>
      sectionErrorText(l10n, ApiFailure(statusCode: status, code: code, message: 'server words'));

  test("says in the app's own words what each refusal of the section endpoints means", () {
    expect(text(400, 'VALIDATION_FAILED'), 'Check the fields marked in red.');
    expect(text(409, 'DUPLICATE'), 'Another section of this class already has this name.');
    expect(text(409, 'VERSION_CONFLICT'), 'Someone else changed this. Your changes were not saved.');
    expect(text(409, 'HAS_STUDENTS'), 'Students are placed in this section. Move them first.');
    expect(text(422, 'REFERENCE_INACTIVE'), 'Something you chose is no longer available. Choose again.');
    expect(text(404, 'NOT_FOUND'), 'This section could not be found. It may have been deactivated.');
    expect(text(403, 'FORBIDDEN'), "You don't have access to this.");
  });

  test('a 404 about the class, when reading or adding sections, names the class', () {
    const failure = ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x');
    expect(
      sectionErrorText(l10n, failure, classGone: true),
      'This class could not be found. It may have been deactivated.',
    );
  });

  group('under a field', () {
    ApiFailure failure(String field, String code) => ApiFailure(
      statusCode: 409,
      code: code,
      message: 'm',
      fieldErrors: [FieldError(field: field, code: code, message: 'Server words')],
    );

    test('a taken name and a taken section are said in the app words', () {
      expect(
        sectionFieldError(l10n, failure('displayName', 'DUPLICATE'), 'displayName'),
        'Another section of this class has this name.',
      );
      expect(
        sectionFieldError(l10n, failure('predefinedSectionId', 'DUPLICATE'), 'predefinedSectionId'),
        'This section is already added to this class.',
      );
      expect(
        sectionFieldError(l10n, failure('predefinedSectionId', 'REFERENCE_INACTIVE'), 'predefinedSectionId'),
        'Something you chose is no longer available. Choose again.',
      );
    });

    test('anything else keeps the words the server gave, and a field not named says nothing', () {
      expect(sectionFieldError(l10n, failure('capacity', 'INVALID'), 'capacity'), 'Server words');
      expect(sectionFieldError(l10n, failure('capacity', 'INVALID'), 'displayName'), isNull);
    });
  });
}
