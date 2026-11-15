import 'package:bravynix_school_erp/core/network/api_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _body(Object? meta) => {
  'success': true,
  'statusCode': 201,
  'code': 'CREATED',
  'message': 'ok',
  'data': 'x',
  'meta': meta,
  'requestId': 'r1',
};

void main() {
  group('warnings', () {
    test('are the codes in meta.warnings', () {
      final envelope = ApiEnvelope.parse<String>(
        _body({
          'warnings': ['SECTION_OVER_CAPACITY', 'AADHAAR_EXISTS_IN_SOCIETY'],
        }),
        (data) => data! as String,
      );
      expect(envelope.warnings, ['SECTION_OVER_CAPACITY', 'AADHAAR_EXISTS_IN_SOCIETY']);
    });

    test('are none when meta is null, a page, or holds something else', () {
      expect(ApiEnvelope.parse<String>(_body(null), (data) => data! as String).warnings, isEmpty);
      expect(
        ApiEnvelope.parse<String>(
          _body({'page': 1, 'limit': 20, 'totalItems': 3, 'totalPages': 1}),
          (data) => data! as String,
        ).warnings,
        isEmpty,
      );
      expect(
        ApiEnvelope.parse<String>(_body({'warnings': 'X'}), (data) => data! as String).warnings,
        isEmpty,
      );
    });

    test('leave out anything that is not a code', () {
      final envelope = ApiEnvelope.parse<String>(
        _body({
          'warnings': ['A', 3, null],
        }),
        (data) => data! as String,
      );
      expect(envelope.warnings, ['A']);
    });
  });
}
