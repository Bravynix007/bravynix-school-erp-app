import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';

/// JSON → domain for INS-01 and INS-03. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class InstitutionModels {
  static Map<String, dynamic> _object(Object? json) =>
      json is Map<String, dynamic> ? json : throw const FormatException('Expected a JSON object');

  static List<dynamic> _list(Object? json) =>
      json is List<dynamic> ? json : throw const FormatException('Expected a JSON array');

  static InstitutionSummary summary(Object? raw) {
    final json = _object(raw);
    return InstitutionSummary(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      place: json['place'] as String?,
      board: Board.fromCode(json['boardCode']),
    );
  }

  static List<InstitutionSummary> summaries(Object? raw) => [for (final item in _list(raw)) summary(item)];

  static String? _phone(Object? raw) {
    if (raw == null) return null;
    final json = _object(raw);
    return '+${json['countryCode']} ${json['number']}';
  }

  static Institution institution(Object? raw) {
    final json = _object(raw);
    final address = _object(json['address']);
    return Institution(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      place: json['place'] as String?,
      board: Board.fromCode(json['boardCode']),
      affiliationNumber: json['affiliationNumber'] as String?,
      gstin: json['gstin'] as String?,
      email: json['email'] as String?,
      phone: _phone(json['phone']),
      telephone: json['telephone'] as String?,
      addressLine1: address['line1'] as String,
      addressLine2: address['line2'] as String?,
      pincode: address['pincode'] as String?,
      classesOffered: [
        for (final item in _list(json['classesOffered']))
          OfferedCategory(id: _object(item)['id'] as String, name: _object(item)['name'] as String),
      ],
    );
  }
}
