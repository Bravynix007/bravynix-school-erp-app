import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';

/// JSON → domain for AY-01 to AY-04. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class AcademicYearModels {
  static AcademicYear year(Object? raw) {
    final json = jsonObject(raw);
    return AcademicYear(
      id: json['id'] as String,
      institutionId: json['institutionId'] as String,
      name: json['name'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      isCurrent: json['isCurrent'] as bool,
      version: (json['version'] as num).toInt(),
    );
  }

  static List<AcademicYear> years(Object? raw) => [for (final item in jsonList(raw)) year(item)];

  /// AY-02.
  static Map<String, Object?> createBody(
    String institutionId, {
    required String name,
    required String startDate,
    required String endDate,
  }) => {'institutionId': institutionId, 'name': name, 'startDate': startDate, 'endDate': endDate};

  /// AY-03: the three editable fields and the version that was read.
  static Map<String, Object?> updateBody(
    AcademicYear year, {
    required String name,
    required String startDate,
    required String endDate,
  }) => {'version': year.version, 'name': name, 'startDate': startDate, 'endDate': endDate};
}
