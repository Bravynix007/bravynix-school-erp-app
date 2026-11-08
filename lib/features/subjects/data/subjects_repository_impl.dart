import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/subjects/data/subject_models.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';

class SubjectsRepositoryImpl implements SubjectsRepository {
  const new({required this._api});

  final ApiClient _api;

  static String _path(String id) => 'subjects/${Uri.encodeComponent(id)}';

  @override
  Future<List<Subject>> subjects() => _api.data('subjects', parse: SubjectModels.subjects);

  @override
  Future<Subject> create({required String name, String? code}) => _api.data(
    'subjects',
    method: HttpMethod.post,
    body: SubjectModels.createBody(name: name, code: code),
    parse: SubjectModels.subject,
  );

  @override
  Future<Subject> update(Subject subject, {required String name, String? code}) => _api.data(
    _path(subject.id),
    method: HttpMethod.patch,
    body: SubjectModels.updateBody(subject, name: name, code: code),
    parse: SubjectModels.subject,
  );

  @override
  Future<void> deactivate(String id) => _api.data(_path(id), method: HttpMethod.delete, parse: (_) {});
}
