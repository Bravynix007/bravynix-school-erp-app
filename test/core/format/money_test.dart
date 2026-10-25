import 'package:bravynix_school_erp/core/format/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatRupees', () {
    test('groups digits the Indian way', () {
      expect(formatRupees('0'), '₹0.00');
      expect(formatRupees('7'), '₹7.00');
      expect(formatRupees('999.5'), '₹999.50');
      expect(formatRupees('1000'), '₹1,000.00');
      expect(formatRupees('12500.00'), '₹12,500.00');
      expect(formatRupees('124500.00'), '₹1,24,500.00');
      expect(formatRupees('1234567.89'), '₹12,34,567.89');
      expect(formatRupees('123456789.01'), '₹12,34,56,789.01');
    });

    test('keeps the paise exactly as sent, with no rounding', () {
      expect(formatRupees('0.05'), '₹0.05');
      expect(formatRupees('10.1'), '₹10.10');
      expect(formatRupees('9007199254740993.99'), '₹9,00,71,99,25,47,40,993.99', reason: 'beyond what a double holds');
    });

    test('negative amounts, leading zeros and the symbol switch', () {
      expect(formatRupees('-250'), '-₹250.00');
      expect(formatRupees('-1234.5'), '-₹1,234.50');
      expect(formatRupees('-0.00'), '₹0.00');
      expect(formatRupees('00012'), '₹12.00');
      expect(formatRupees('124500', withSymbol: false), '1,24,500.00');
    });

    test('refuses what is not a plain decimal, instead of showing a wrong amount', () {
      for (final bad in ['', 'abc', '1,250.00', '12.345', '1e5', '.5', '₹10', '1.', '--5']) {
        expect(() => formatRupees(bad), throwsFormatException, reason: bad);
      }
    });
  });
}
