import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/people/domain/place_names.dart';
import 'package:bravynix_school_erp/features/people/presentation/view/person_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/staff.dart';

void main() {
  late MockMastersRepository masters;

  setUpAll(() => registerFallbackValue(MasterType.countries));
  setUp(() {
    masters = MockMastersRepository();
    when(() => masters.entries(MasterType.countries)).thenAnswer((_) async => [countryEntry]);
    when(() => masters.entries(MasterType.states, parentId: 'k1')).thenAnswer((_) async => [stateEntry]);
    when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) async => [cityEntry]);
  });

  group('placeNamesOf', () {
    test('names the country, the state under the country and the city under the state', () async {
      const address = Address(countryId: 'k1', stateId: 's1', cityId: 'y1');
      expect(
        await masters.placeNamesOf(address),
        const PlaceNames(country: 'India', state: 'Karnataka', city: 'Bengaluru'),
      );
    });

    test('has no name for a place the address does not hold, and reads nothing for it', () async {
      expect(await masters.placeNamesOf(const Address(line1: '12 Lake Road')), const PlaceNames());
      verifyZeroInteractions(masters);
    });

    test('reads no city for an address without a state, whatever city it names', () async {
      const address = Address(countryId: 'k1', cityId: 'y1');
      expect(await masters.placeNamesOf(address), const PlaceNames(country: 'India'));
      verifyNever(() => masters.entries(MasterType.cities, parentId: any(named: 'parentId')));
    });

    test('has no name for a place the master no longer shows', () async {
      when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) async => []);
      const address = Address(countryId: 'k1', stateId: 's1', cityId: 'y1');
      expect(await masters.placeNamesOf(address), const PlaceNames(country: 'India', state: 'Karnataka'));
    });
  });

  group('addressText', () {
    const places = PlaceNames(country: 'India', state: 'Karnataka', city: 'Bengaluru');

    test('is a line for each address line, the places and the pincode', () {
      const address = Address(line1: '12 Lake Road', line2: 'Near the park', pincode: '560066');
      expect(addressText(address, places), '12 Lake Road\nNear the park\nBengaluru, Karnataka, India\n560066');
    });

    test('leaves out what is not there, and is empty for an address with nothing', () {
      expect(
        addressText(const Address(line1: '12 Lake Road'), const PlaceNames(country: 'India')),
        '12 Lake Road\nIndia',
      );
      expect(addressText(const Address(), const PlaceNames()), isEmpty);
    });
  });
}
