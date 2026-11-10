import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_envelope.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/staff/data/staff_models.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';

class StaffRepositoryImpl implements StaffRepository {
  const new({required this._api});

  final ApiClient _api;

  static String _path(String id) => 'staff/${Uri.encodeComponent(id)}';

  @override
  Future<ItemsPage<StaffSummary>> staff(String institutionId, {int page = 1, String query = ''}) async {
    final answer = await _api.request(
      'staff',
      query: {'institutionId': institutionId, 'page': page, 'q': query.isEmpty ? null : query},
      parse: StaffModels.summaries,
    );
    // An answer without page numbers is the whole list.
    final meta = answer.meta;
    return ItemsPage(answer.data, page: page, totalPages: meta is NumberedPage ? meta.totalPages : page);
  }

  @override
  Future<StaffMember> member(String id) => _api.data(_path(id), parse: StaffModels.member);

  @override
  Future<void> deactivate(String id) => _api.data(_path(id), method: HttpMethod.delete, parse: (_) {});
}
