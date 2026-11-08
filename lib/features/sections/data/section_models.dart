import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';

/// JSON → domain for SEC-01 to SEC-03. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class SectionModels {
  static Section section(Object? raw) {
    final json = jsonObject(raw);
    final predefined = jsonObject(json['predefinedSection']);
    return Section(
      id: json['id'] as String,
      classId: json['classId'] as String,
      predefinedSection: NamedRef(
        id: predefined['id'] as String,
        code: predefined['code'] as String,
        name: predefined['name'] as String,
      ),
      displayName: json['displayName'] as String,
      capacity: (json['capacity'] as num?)?.toInt(),
      currentStudentCount: (json['currentStudentCount'] as num?)?.toInt(),
      version: (json['version'] as num).toInt(),
    );
  }

  static List<Section> sections(Object? raw) => [for (final item in jsonList(raw)) section(item)];

  /// SEC-02: what is set is sent; what is empty is left out.
  static Map<String, Object?> createBody(
    String classId, {
    required String predefinedSectionId,
    String? displayName,
    int? capacity,
  }) => {
    'classId': classId,
    'predefinedSectionId': predefinedSectionId,
    'displayName': ?displayName,
    'capacity': ?capacity,
  };

  /// SEC-03: the name, the capacity (`null` clears it) and the version that was read.
  static Map<String, Object?> updateBody(Section section, {required String displayName, int? capacity}) => {
    'version': section.version,
    'displayName': displayName,
    'capacity': capacity,
  };
}
