import 'package:bravynix_school_erp/features/institutions/data/institution_models.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/institutions.dart';

void main() {
  test('reads every row of INS-01, ignoring the fields it does not show', () {
    final list = InstitutionModels.summaries([summaryJson(), summaryJson(id: 'i2', boardCode: 6, place: null)]);
    expect(list.first, summary());
    expect(list.last, summary(id: 'i2', place: null, board: Board.other));
  });

  test('reads an Institution with all its fields from INS-03', () {
    expect(InstitutionModels.institution(institutionJson()), institution);
  });

  test('reads an Institution with only what is required', () {
    final read = InstitutionModels.institution({
      'id': 'i2',
      'code': 'LVS',
      'name': 'Lake View School',
      'place': null,
      'boardCode': null,
      'affiliationNumber': null,
      'gstin': null,
      'email': null,
      'phone': null,
      'telephone': null,
      'address': {'line1': '3 Hill Street', 'line2': null, 'pincode': null},
      'classesOffered': <Object?>[],
    });
    expect(read, bareInstitution);
  });

  test('a board it does not know is left out, not guessed', () {
    expect(InstitutionModels.summary(summaryJson(boardCode: 9)).board, isNull);
    expect(InstitutionModels.summary(summaryJson(boardCode: null)).board, isNull);
  });

  test('refuses an answer it cannot read instead of showing a wrong Institution', () {
    expect(() => InstitutionModels.summaries('nope'), throwsFormatException);
    expect(() => InstitutionModels.institution(<Object?>[]), throwsFormatException);
    expect(() => InstitutionModels.institution({...institutionJson(), 'address': null}), throwsFormatException);
  });
}
