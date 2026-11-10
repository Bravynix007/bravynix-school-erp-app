import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_envelope.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/institutions/data/institution_models.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution_admin.dart';
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
  Future<Institution> create(InstitutionDraft draft) => _api.data(
    'institutions',
    method: HttpMethod.post,
    body: InstitutionModels.createBody(draft),
    parse: InstitutionModels.institution,
  );

  @override
  Future<Institution> update(String id, int version, InstitutionDraft draft) => _api.data(
    _path(id),
    method: HttpMethod.patch,
    body: InstitutionModels.updateBody(draft, version),
    parse: InstitutionModels.institution,
  );

  @override
  Future<void> deactivate(String id) => _api.data(_path(id), method: HttpMethod.delete, parse: (_) {});

  @override
  Future<ItemsPage<InstitutionAdmin>> admins(String institutionId, {int page = 1}) async {
    final answer = await _api.request(
      '${_path(institutionId)}/admins',
      query: {'page': page},
      parse: InstitutionModels.admins,
    );
    final meta = answer.meta;
    return ItemsPage(answer.data, page: page, totalPages: meta is NumberedPage ? meta.totalPages : page);
  }

  @override
  Future<InstitutionAdmin> grantAdmin(String institutionId, String staffMemberId) => _api.data(
    '${_path(institutionId)}/admins',
    method: HttpMethod.post,
    body: {'staffMemberId': staffMemberId},
    parse: InstitutionModels.admin,
  );

  @override
  Future<void> revokeAdmin(String institutionId, String staffMemberId) => _api.data(
    '${_path(institutionId)}/admins/${Uri.encodeComponent(staffMemberId)}',
    method: HttpMethod.delete,
    parse: (_) {},
  );
}
