import 'dart:ui';

import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  String text(int status, String code) =>
      classErrorText(l10n, ApiFailure(statusCode: status, code: code, message: 'server words'));

  test("says in the app's own words what each refusal of the class endpoints means", () {
    expect(text(400, 'VALIDATION_FAILED'), 'Check the fields marked in red.');
    expect(text(409, 'DUPLICATE'), 'Another class of this Institution already has this name or stream.');
    expect(text(409, 'VERSION_CONFLICT'), 'Someone else changed this. Your changes were not saved.');
    expect(text(409, 'HAS_STUDENTS'), 'Students are placed in this class. Move them first.');
    expect(
      text(422, 'CLASS_NOT_OFFERED'),
      "This Institution does not offer this class's category. Tick the category on the Institution first.",
    );
    expect(text(422, 'STREAM_NOT_ALLOWED'), 'Only Pre-University classes have a stream.');
    expect(text(422, 'REFERENCE_INACTIVE'), 'Something you chose is no longer available. Choose again.');
    expect(text(404, 'NOT_FOUND'), 'This class could not be found. It may have been deactivated.');
    expect(text(403, 'FORBIDDEN'), "You don't have access to this.");
  });

  group('under a field', () {
    ApiFailure failure(String field, String code) => ApiFailure(
      statusCode: 409,
      code: code,
      message: 'm',
      fieldErrors: [FieldError(field: field, code: code, message: 'Server words')],
    );

    test('a taken name and a taken class are said in the app words', () {
      expect(
        classFieldError(l10n, failure('displayName', 'DUPLICATE'), 'displayName'),
        'Another class of this Institution has this name.',
      );
      expect(
        classFieldError(l10n, failure('streamName', 'DUPLICATE'), 'streamName'),
        'This class is already added to this Institution.',
      );
      expect(
        classFieldError(l10n, failure('predefinedClassId', 'DUPLICATE'), 'predefinedClassId'),
        'This class is already added to this Institution.',
      );
    });

    test('the two 422 refusals and an inactive class are said in the app words', () {
      expect(
        classFieldError(l10n, failure('streamName', 'STREAM_NOT_ALLOWED'), 'streamName'),
        'Only Pre-University classes have a stream.',
      );
      expect(
        classFieldError(l10n, failure('predefinedClassId', 'CLASS_NOT_OFFERED'), 'predefinedClassId'),
        startsWith('This Institution does not offer'),
      );
      expect(
        classFieldError(l10n, failure('predefinedClassId', 'REFERENCE_INACTIVE'), 'predefinedClassId'),
        'Something you chose is no longer available. Choose again.',
      );
    });

    test('any other refusal of the field keeps the words the server gave', () {
      expect(classFieldError(l10n, failure('displayName', 'TOO_LONG'), 'displayName'), 'Server words');
    });

    test('a field the refusal does not name has nothing to say', () {
      expect(classFieldError(l10n, failure('displayName', 'DUPLICATE'), 'code'), isNull);
    });
  });

  group('Add several', () {
    ApiFailure refused(List<FieldError> fields) =>
        ApiFailure(statusCode: 409, code: 'DUPLICATE', message: 'm', fieldErrors: fields);
    const names = ['Class 1', 'Class 2', 'Class 3'];

    test('names the class a refusal is about, from the item it names', () {
      expect(
        classBulkErrorText(
          l10n,
          refused(const [FieldError(field: 'classes[1].displayName', code: 'DUPLICATE', message: 'x')]),
          names,
        ),
        'Class 2: Another class of this Institution has this name.',
      );
      expect(
        classBulkErrorText(
          l10n,
          refused(const [FieldError(field: 'classes[0].predefinedClassId', code: 'DUPLICATE', message: 'x')]),
          names,
        ),
        'Class 1: This class is already added to this Institution.',
      );
    });

    test('says the first item that is named, and the 422 refusals in their words', () {
      expect(
        classBulkErrorText(
          l10n,
          refused(const [FieldError(field: 'classes[2].predefinedClassId', code: 'CLASS_NOT_OFFERED', message: 'x')]),
          names,
        ),
        startsWith('Class 3: This Institution does not offer'),
      );
    });

    test('a refusal that names no item, or one that was not sent, reads as everywhere else', () {
      expect(classBulkErrorText(l10n, refused(const []), names), text(409, 'DUPLICATE'));
      expect(
        classBulkErrorText(
          l10n,
          refused(const [FieldError(field: 'classes[7].displayName', code: 'DUPLICATE', message: 'x')]),
          names,
        ),
        text(409, 'DUPLICATE'),
      );
      expect(
        classBulkErrorText(
          l10n,
          refused(const [FieldError(field: 'institutionId', code: 'DUPLICATE', message: 'x')]),
          names,
        ),
        text(409, 'DUPLICATE'),
      );
    });
  });
}
