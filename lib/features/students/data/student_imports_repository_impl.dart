import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/students/data/student_import_models.dart';
import 'package:bravynix_school_erp/features/students/domain/student_import.dart';

class StudentImportsRepositoryImpl implements StudentImportsRepository {
  const new({required this._api});

  final ApiClient _api;

  @override
  Future<String> template() => _api.text('imports/templates/students');

  @override
  Future<String> start({
    required String institutionId,
    required String fileId,
    required String academicYearId,
    required String idempotencyKey,
  }) => _api.data(
    'imports',
    method: HttpMethod.post,
    idempotencyKey: idempotencyKey,
    body: {'institutionId': institutionId, 'importType': 1, 'fileId': fileId, 'academicYearId': academicYearId},
    parse: StudentImportModels.importId,
  );

  @override
  Future<StudentImport> status(String importId) =>
      _api.data('imports/${Uri.encodeComponent(importId)}', parse: StudentImportModels.run);
}
