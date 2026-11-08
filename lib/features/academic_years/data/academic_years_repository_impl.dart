import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/academic_years/data/academic_year_models.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';

class AcademicYearsRepositoryImpl implements AcademicYearsRepository {
  const new({required this._api});

  final ApiClient _api;

  static String _path(String id) => 'academic-years/${Uri.encodeComponent(id)}';

  @override
  Future<List<AcademicYear>> years(String institutionId) =>
      _api.data('academic-years', query: {'institutionId': institutionId}, parse: AcademicYearModels.years);

  @override
  Future<AcademicYear> create(
    String institutionId, {
    required String name,
    required String startDate,
    required String endDate,
  }) => _api.data(
    'academic-years',
    method: HttpMethod.post,
    body: AcademicYearModels.createBody(institutionId, name: name, startDate: startDate, endDate: endDate),
    parse: AcademicYearModels.year,
  );

  @override
  Future<AcademicYear> update(
    AcademicYear year, {
    required String name,
    required String startDate,
    required String endDate,
  }) => _api.data(
    _path(year.id),
    method: HttpMethod.patch,
    body: AcademicYearModels.updateBody(year, name: name, startDate: startDate, endDate: endDate),
    parse: AcademicYearModels.year,
  );

  @override
  Future<AcademicYear> makeCurrent(AcademicYear year) => _api.data(
    '${_path(year.id)}/make-current',
    method: HttpMethod.post,
    body: {'version': year.version},
    parse: AcademicYearModels.year,
  );

  @override
  Future<void> deactivate(String id) => _api.data(_path(id), method: HttpMethod.delete, parse: (_) {});
}
