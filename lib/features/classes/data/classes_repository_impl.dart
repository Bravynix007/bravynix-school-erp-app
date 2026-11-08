import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/classes/data/class_models.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';

class ClassesRepositoryImpl implements ClassesRepository {
  const new({required this._api});

  final ApiClient _api;

  static String _path(String id) => 'classes/${Uri.encodeComponent(id)}';

  @override
  Future<List<SchoolClass>> classes(String institutionId) =>
      _api.data('classes', query: {'institutionId': institutionId}, parse: ClassModels.classes);

  @override
  Future<SchoolClass> create(String institutionId, NewClass item, {String? displayName, String? code}) => _api.data(
    'classes',
    method: HttpMethod.post,
    body: ClassModels.createBody(institutionId, item, displayName: displayName, code: code),
    parse: ClassModels.schoolClass,
  );

  @override
  Future<List<SchoolClass>> createMany(String institutionId, List<NewClass> items) => _api.data(
    'classes/bulk',
    method: HttpMethod.post,
    body: ClassModels.bulkBody(institutionId, items),
    parse: ClassModels.classes,
  );

  @override
  Future<SchoolClass> update(SchoolClass schoolClass, {required String displayName, String? code}) => _api.data(
    _path(schoolClass.id),
    method: HttpMethod.patch,
    body: ClassModels.updateBody(schoolClass, displayName: displayName, code: code),
    parse: ClassModels.schoolClass,
  );

  @override
  Future<void> deactivate(String id) => _api.data(_path(id), method: HttpMethod.delete, parse: (_) {});
}
