import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';

/// JSON → domain for SUB-01 to SUB-03. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class SubjectModels {
  static Subject subject(Object? raw) {
    final json = jsonObject(raw);
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      version: (json['version'] as num).toInt(),
    );
  }

  static List<Subject> subjects(Object? raw) => [for (final item in jsonList(raw)) subject(item)];

  /// SUB-02: a subject without a code sends none.
  static Map<String, Object?> createBody({required String name, String? code}) => {'name': name, 'code': ?code};

  /// SUB-03: both editable fields and the version that was read; `null` clears the code.
  static Map<String, Object?> updateBody(Subject subject, {required String name, String? code}) => {
    'version': subject.version,
    'name': name,
    'code': code,
  };
}
