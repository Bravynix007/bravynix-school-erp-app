import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads every part, each of which may be null', () {
    expect(
      Address.fromJson(const {
        'line1': '12 Lake Road',
        'line2': null,
        'countryId': 'k1',
        'stateId': 's1',
        'cityId': 'y1',
        'pincode': '560001',
      }),
      const Address(line1: '12 Lake Road', countryId: 'k1', stateId: 's1', cityId: 'y1', pincode: '560001'),
    );
    expect(Address.fromJson(const <String, Object?>{}).isEmpty, isTrue);
  });

  test('sends what is set, and with clearing the empty parts as null too', () {
    const address = Address(line1: '12 Lake Road', pincode: '560001');
    expect(address.toJson(clearing: false), {'line1': '12 Lake Road', 'pincode': '560001'});
    expect(address.toJson(clearing: true), {
      'line1': '12 Lake Road',
      'line2': null,
      'countryId': null,
      'stateId': null,
      'cityId': null,
      'pincode': '560001',
    });
  });

  test('is empty only when no part is set', () {
    expect(const Address().isEmpty, isTrue);
    expect(const Address(cityId: 'y1').isEmpty, isFalse);
  });

  test('refuses what is not an object', () {
    expect(() => Address.fromJson('x'), throwsFormatException);
  });

  test('is built from the typed lines and pincode, trimmed and empty ones left out, and the place chosen', () {
    expect(
      Address.typed(
        line1: ' 12 Lake Road ',
        line2: '  ',
        pincode: '560001 ',
        countryId: 'k1',
        stateId: 's1',
        cityId: 'y1',
      ),
      const Address(line1: '12 Lake Road', countryId: 'k1', stateId: 's1', cityId: 'y1', pincode: '560001'),
    );
    expect(Address.typed(line1: '', line2: ' ', pincode: '').isEmpty, isTrue);
  });
}
