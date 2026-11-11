import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_envelope.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/staff/data/staff_models.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_draft.dart';
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
  Future<StaffMember> create(String institutionId, StaffDraft draft) => _api.data(
    'staff',
    method: HttpMethod.post,
    body: StaffModels.createBody(institutionId, draft),
    parse: StaffModels.member,
  );

  @override
  Future<StaffMember> update(String id, int version, StaffDraft draft) => _api.data(
    _path(id),
    method: HttpMethod.patch,
    body: StaffModels.updateBody(draft, version),
    parse: StaffModels.member,
  );

  @override
  Future<void> deactivate(String id) => _api.data(_path(id), method: HttpMethod.delete, parse: (_) {});

  @override
  Future<StaffMember> block(String id) =>
      _api.data('${_path(id)}/block', method: HttpMethod.post, parse: StaffModels.member);

  @override
  Future<StaffMember> unblock(String id) =>
      _api.data('${_path(id)}/unblock', method: HttpMethod.post, parse: StaffModels.member);

  @override
  Future<StaffMember> setSubjects(String id, List<String> subjectIds) => _api.data(
    '${_path(id)}/subjects',
    method: HttpMethod.put,
    body: {'subjectIds': subjectIds},
    parse: StaffModels.member,
  );

  @override
  Future<StaffMember> setInstitutions(String id, List<String> institutionIds) => _api.data(
    '${_path(id)}/institutions',
    method: HttpMethod.put,
    body: {'institutionIds': institutionIds},
    parse: StaffModels.member,
  );

  @override
  Future<ClassTeacherAssignment?> setClassTeacher(String id, {required String academicYearId, String? sectionId}) =>
      _api.data(
        '${_path(id)}/class-teacher',
        method: HttpMethod.put,
        body: {'academicYearId': academicYearId, 'sectionId': sectionId},
        parse: (raw) => raw == null ? null : StaffModels.classTeacher(raw),
      );
}
