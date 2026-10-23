import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.money', () {
    const cases = {
      '124500.00': '₹1,24,500.00',
      '0.00': '₹0.00',
      '999': '₹999.00',
      '1000.5': '₹1,000.50',
      '12345678.90': '₹1,23,45,678.90',
      '-94725.00': '-₹94,725.00',
      '007.10': '₹7.10',
    };
    cases.forEach((input, expected) {
      test('$input → $expected', () => expect(Formatters.money(input), expected));
    });

    test('keeps digits a double would lose', () {
      expect(Formatters.money('90071992547409.99'), '₹9,00,71,99,25,47,409.99');
    });

    test('returns anything else unchanged', () => expect(Formatters.money('n/a'), 'n/a'));
  });

  group('dates', () {
    test('a school day has no time zone shift', () => expect(Formatters.schoolDate('2026-10-23'), '23-10-2026'));

    test('instants show in IST, 24 h', () {
      expect(Formatters.instant(DateTime.utc(2026, 10, 23, 4, 45)), '23-10-2026 10:15');
      // 18:30 UTC is already the next day in India.
      expect(Formatters.instant(DateTime.utc(2026, 10, 23, 18, 30)), '24-10-2026 00:00');
    });
  });
}
