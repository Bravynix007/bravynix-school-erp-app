import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ApiFailure failure(List<String> fields) => ApiFailure(
    statusCode: 400,
    code: 'VALIDATION_FAILED',
    message: 'm',
    fieldErrors: [for (final field in fields) FieldError(field: field, code: 'X', message: 'm')],
  );

  group('namesOnly', () {
    const form = {'name', 'code'};

    test('is true when every field the refusal names is on the form', () {
      expect(failure(['name']).namesOnly(form), isTrue);
      expect(failure(['name', 'code']).namesOnly(form), isTrue);
    });

    test('is false when one of them is not, so it is said above the form instead', () {
      expect(failure(['name', 'institutionId']).namesOnly(form), isFalse);
      expect(failure(['classesOffered[1]']).namesOnly(form), isFalse);
    });

    test('is false when the refusal names no field', () {
      expect(failure([]).namesOnly(form), isFalse);
    });
  });
}
