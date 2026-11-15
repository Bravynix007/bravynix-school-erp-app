import 'package:bravynix_school_erp/core/model/typed_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TypedText.text', () {
    test('is the text without the spaces around it, and its own spaces stay', () {
      expect(TypedText.text('  Asha  Rao '), 'Asha  Rao');
    });

    test('is null when nothing is left', () {
      expect(TypedText.text(''), isNull);
      expect(TypedText.text(' \t '), isNull);
    });
  });

  group('TypedText.digits', () {
    test('drops the spaces and hyphens between the digits, as people write numbers', () {
      expect(TypedText.digits(' 98765 43210 '), '9876543210');
      expect(TypedText.digits('98765-43210'), '9876543210');
    });

    test('is null when nothing is left', () {
      expect(TypedText.digits(' - '), isNull);
      expect(TypedText.digits(''), isNull);
    });
  });
}
