import 'package:bravynix_school_erp/core/model/aadhaar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('a number as typed', () {
    test('is the twelve digits, with spaces and hyphens taken out', () {
      expect(Aadhaar.typed('234567890123'), '234567890123');
      expect(Aadhaar.typed('2345 6789 0123'), '234567890123');
      expect(Aadhaar.typed(' 2345-6789-0123 '), '234567890123');
    });

    test('is nothing when it is not twelve digits', () {
      expect(Aadhaar.typed(''), isNull);
      expect(Aadhaar.typed('23456789012'), isNull);
      expect(Aadhaar.typed('2345678901234'), isNull);
      expect(Aadhaar.typed('2345 6789 01x3'), isNull);
    });

    test('is nothing when the first digit is 0 or 1', () {
      expect(Aadhaar.typed('034567890123'), isNull);
      expect(Aadhaar.typed('134567890123'), isNull);
      expect(Aadhaar.typed('934567890123'), '934567890123');
    });
  });

  test('is shown in groups of four', () {
    expect(Aadhaar.grouped('234567890123'), '2345 6789 0123');
    expect(Aadhaar.grouped('2345'), '2345');
    expect(Aadhaar.grouped(''), '');
  });
}
