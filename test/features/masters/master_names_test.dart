import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/staff.dart';

void main() {
  late MockMastersRepository masters;
  setUpAll(() => registerFallbackValue(MasterType.countries));
  setUp(() => masters = MockMastersRepository());

  test('names the entry with the ID, wherever it stands in the master', () async {
    when(() => masters.entries(MasterType.designations)).thenAnswer((_) async => [otherDesignation, designationEntry]);
    expect(await masters.nameOf(MasterType.designations, 'd1'), 'Mathematics Teacher');
    expect(await masters.nameOf(MasterType.designations, 'd2'), 'Principal');
  });

  test('has no name for an entry the master no longer shows', () async {
    when(() => masters.entries(MasterType.designations)).thenAnswer((_) async => [otherDesignation]);
    expect(await masters.nameOf(MasterType.designations, 'd1'), isNull);
  });

  test('reads nothing for no ID, and passes the parent on', () async {
    when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) async => [cityEntry]);
    expect(await masters.nameOf(MasterType.cities, null, parentId: 's1'), isNull);
    verifyNever(() => masters.entries(any(), parentId: any(named: 'parentId')));
    expect(await masters.nameOf(MasterType.cities, 'y1', parentId: 's1'), 'Bengaluru');
  });
}
