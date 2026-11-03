import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/institutions/data/institution_models.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';

class InstitutionsRepositoryImpl implements InstitutionsRepository {
  const new({required this._api});

  final ApiClient _api;

  static String _path(String id) => 'institutions/${Uri.encodeComponent(id)}';

  @override
  Future<List<InstitutionSummary>> institutions() => _api.data('institutions', parse: InstitutionModels.summaries);

  @override
  Future<Institution> institution(String id) => _api.data(_path(id), parse: InstitutionModels.institution);

  @override
  Future<void> deactivate(String id) => _api.data(_path(id), method: HttpMethod.delete, parse: (_) {});
}
