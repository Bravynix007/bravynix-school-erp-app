import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phone.typed', () {
    test('takes the dial code without a plus and the number without spaces', () {
      expect(Phone.typed(' +91 ', '98765 43210'), const Phone(countryCode: '91', number: '9876543210'));
    });

    test('is no phone when no number was typed, whatever the dial code', () {
      expect(Phone.typed('91', ''), isNull);
      expect(Phone.typed('91', '   '), isNull);
    });

    test('keeps a number without its dial code, so the API names the field', () {
      expect(Phone.typed('', '98'), const Phone(countryCode: '', number: '98'));
    });
  });

  test('reads and writes the API shape, and shows +code number', () {
    const phone = Phone(countryCode: '91', number: '9876543210');
    expect(Phone.fromJson(phone.toJson()), phone);
    expect(phone.display, '+91 9876543210');
  });
}
