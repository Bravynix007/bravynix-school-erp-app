import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';

/// JSON → domain for MST-01. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class MasterModels {
  static Map<String, dynamic> _object(Object? json) =>
      json is Map<String, dynamic> ? json : throw const FormatException('Expected a JSON object');

  static MasterEntry entry(Object? raw) {
    final json = _object(raw);
    return MasterEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      parentId: (json['countryId'] ?? json['stateId'] ?? json['classCategoryId']) as String?,
      numericValue: (json['numericValue'] as num?)?.toInt(),
    );
  }

  static List<MasterEntry> entries(Object? raw) {
    if (raw is! List<dynamic>) throw const FormatException('Expected a JSON array');
    return [for (final item in raw) entry(item)];
  }
}
