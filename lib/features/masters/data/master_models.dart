import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';

/// JSON → domain for MST-01. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class MasterModels {
  static MasterEntry entry(Object? raw) {
    final json = jsonObject(raw);
    return MasterEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      parentId: (json['countryId'] ?? json['stateId'] ?? json['classCategoryId']) as String?,
      numericValue: (json['numericValue'] as num?)?.toInt(),
    );
  }

  static List<MasterEntry> entries(Object? raw) {
    return [for (final item in jsonList(raw)) entry(item)];
  }
}
