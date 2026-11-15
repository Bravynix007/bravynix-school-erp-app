import 'package:bravynix_school_erp/core/validation/field_problems.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finds nothing wrong when nothing was reported', () {
    final problems = FieldProblems()
      ..requireText('firstName', 'Asha')
      ..requireChoice('classId', 'k1');
    expect(problems.failure, isNull);
  });

  test('names each empty required field, a text of only spaces among them, in the order they were asked', () {
    final failure =
        (FieldProblems()
              ..requireText('firstName', '  ')
              ..requireChoice('classId', null)
              ..requireText('rollNumber', '14')
              ..add('aadhaar', 'INVALID_AADHAAR'))
            .failure!;
    expect(failure.code, 'VALIDATION_FAILED');
    expect(failure.statusCode, 400);
    expect(failure.fieldErrors.map((error) => [error.field, error.code]), [
      ['firstName', 'REQUIRED'],
      ['classId', 'REQUIRED'],
      ['aadhaar', 'INVALID_AADHAAR'],
    ]);
    expect(failure.namesOnly({'firstName', 'classId', 'aadhaar'}), isTrue);
  });
}
