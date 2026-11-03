import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';

/// The academic years of an Institution (AY-01 to AY-05). Methods throw [ApiFailure].
abstract class AcademicYearsRepository {
  /// AY-01: the active years, the latest start first.
  Future<List<AcademicYear>> years(String institutionId);

  /// AY-02: the first year of an Institution becomes current by itself. 409 DUPLICATE on the name, 409 YEAR_OVERLAP.
  Future<AcademicYear> create(
    String institutionId, {
    required String name,
    required String startDate,
    required String endDate,
  });

  /// AY-03: sends the three fields with the version that was read. 409 VERSION_CONFLICT when it changed meanwhile.
  Future<AcademicYear> update(
    AcademicYear year, {
    required String name,
    required String startDate,
    required String endDate,
  });

  /// AY-04: the year becomes current and the one that was current stops being.
  Future<AcademicYear> makeCurrent(AcademicYear year);

  /// AY-05: deactivates the year; nothing is deleted. 409 CURRENT_YEAR_LOCKED for the current year.
  Future<void> deactivate(String id);
}
