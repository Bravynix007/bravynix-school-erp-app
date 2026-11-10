import 'package:bravynix_school_erp/core/model/phone.dart';
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
      'address': {
        'line1': '3 Hill Street',
        'line2': null,
        'pincode': null,
        'countryId': null,
        'stateId': null,
        'cityId': null,
      },
      'classesOffered': <Object?>[],
      'version': 1,
    });
    expect(read, bareInstitution);
  });

  test('reads each of the six board codes as its own board (PRD 11.4)', () {
    expect(
      [for (var code = 1; code <= 6; code++) InstitutionModels.summary(summaryJson(boardCode: code)).board],
      [Board.cbse, Board.icse, Board.stateBoard, Board.ib, Board.igcse, Board.other],
    );
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

  group('the body of INS-02 and INS-04', () {
    const full = InstitutionDraft(
      name: 'Sri Vidya High School',
      code: 'SVHS',
      addressLine1: '12 Lake Road',
      classesOffered: ['c1', 'c2'],
      place: 'Whitefield',
      board: Board.cbse,
      affiliationNumber: '830123',
      gstin: '29ABCDE1234F1Z5',
      email: 'office@svhs.example.org',
      phone: Phone(countryCode: '91', number: '9876543210'),
      telephone: '080 2345 6789',
      addressLine2: 'Near the park',
      pincode: '560066',
      countryId: 'k1',
      stateId: 's1',
      cityId: 'y1',
    );
    const bare = InstitutionDraft(
      name: 'Lake View School',
      code: 'LVS',
      addressLine1: '3 Hill Street',
      classesOffered: [],
    );

    test('an edit sends the version, every field and never the code', () {
      expect(InstitutionModels.updateBody(full, 3), {
        'version': 3,
        'name': 'Sri Vidya High School',
        'classesOffered': ['c1', 'c2'],
        'place': 'Whitefield',
        'boardCode': 1,
        'affiliationNumber': '830123',
        'gstin': '29ABCDE1234F1Z5',
        'email': 'office@svhs.example.org',
        'telephone': '080 2345 6789',
        'phone': {'countryCode': '91', 'number': '9876543210'},
        'address': {
          'line1': '12 Lake Road',
          'line2': 'Near the park',
          'pincode': '560066',
          'countryId': 'k1',
          'stateId': 's1',
          'cityId': 'y1',
        },
      });
    });

    test('an edit sends null for what the form left empty, so it is cleared, and the address whole', () {
      expect(InstitutionModels.updateBody(bare, 1), {
        'version': 1,
        'name': 'Lake View School',
        'classesOffered': <String>[],
        'place': null,
        'boardCode': null,
        'affiliationNumber': null,
        'gstin': null,
        'email': null,
        'telephone': null,
        'phone': null,
        'address': {
          'line1': '3 Hill Street',
          'line2': null,
          'pincode': null,
          'countryId': null,
          'stateId': null,
          'cityId': null,
        },
      });
    });

    test('an add sends the code and leaves out what the form left empty', () {
      expect(InstitutionModels.createBody(bare), {
        'name': 'Lake View School',
        'code': 'LVS',
        'classesOffered': <String>[],
        'address': {'line1': '3 Hill Street'},
      });
      expect(InstitutionModels.createBody(full)['code'], 'SVHS');
      expect(InstitutionModels.createBody(full).containsKey('version'), isFalse);
    });
  });
}
