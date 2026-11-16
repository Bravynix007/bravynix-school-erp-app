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

  group('isStoredRefusal', () {
    ApiFailure answer(int status, String code, {Duration? retryAfter}) =>
        ApiFailure(statusCode: status, code: code, message: 'm', retryAfter: retryAfter);

    test('is true for a 409 or 422 the server keeps under the key', () {
      expect(answer(409, 'IMPORT_ALREADY_RUNNING').isStoredRefusal, isTrue);
      expect(answer(422, 'TARGET_CLASS_BELOW_SOURCE').isStoredRefusal, isTrue);
    });

    test('is false for a 409 about the key itself, or one with a try later', () {
      expect(answer(409, 'IDEMPOTENCY_IN_PROGRESS').isStoredRefusal, isFalse);
      expect(answer(422, 'IDEMPOTENCY_KEY_REUSED').isStoredRefusal, isFalse);
      expect(answer(409, 'IMPORT_ALREADY_RUNNING', retryAfter: const Duration(seconds: 5)).isStoredRefusal, isFalse);
    });

    test('is false for a failure the server keeps nothing for', () {
      expect(answer(400, 'VALIDATION_FAILED').isStoredRefusal, isFalse);
      expect(answer(404, 'NOT_FOUND').isStoredRefusal, isFalse);
      expect(answer(503, 'UNAVAILABLE').isStoredRefusal, isFalse);
      expect(const ApiFailure.network().isStoredRefusal, isFalse);
    });
  });
}
