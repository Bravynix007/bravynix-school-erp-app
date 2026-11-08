import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';

/// JSON → domain for CLS-01 to CLS-04. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class ClassModels {
  static NamedRef _ref(Object? raw) {
    final json = jsonObject(raw);
    return NamedRef(id: json['id'] as String, code: json['code'] as String, name: json['name'] as String);
  }

  static SchoolClass schoolClass(Object? raw) {
    final json = jsonObject(raw);
    return SchoolClass(
      id: json['id'] as String,
      institutionId: json['institutionId'] as String,
      predefinedClass: _ref(json['predefinedClass']),
      category: _ref(json['category']),
      streamName: json['streamName'] as String?,
      displayName: json['displayName'] as String,
      code: json['code'] as String?,
      sectionCount: (json['sectionCount'] as num).toInt(),
      version: (json['version'] as num).toInt(),
    );
  }

  static List<SchoolClass> classes(Object? raw) => [for (final item in jsonList(raw)) schoolClass(item)];

  static Map<String, Object?> _item(NewClass item) => {
    'predefinedClassId': item.predefinedClassId,
    'streamName': ?item.streamName,
  };

  /// CLS-02: what is set is sent; what is empty is left out.
  static Map<String, Object?> createBody(String institutionId, NewClass item, {String? displayName, String? code}) => {
    'institutionId': institutionId,
    ..._item(item),
    'displayName': ?displayName,
    'code': ?code,
  };

  /// CLS-03.
  static Map<String, Object?> bulkBody(String institutionId, List<NewClass> items) => {
    'institutionId': institutionId,
    'classes': [for (final item in items) _item(item)],
  };

  /// CLS-04: the name, the code (`null` clears it) and the version that was read.
  static Map<String, Object?> updateBody(SchoolClass schoolClass, {required String displayName, String? code}) => {
    'version': schoolClass.version,
    'displayName': displayName,
    'code': code,
  };
}
