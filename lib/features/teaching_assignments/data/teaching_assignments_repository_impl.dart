import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_envelope.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/data/teaching_assignment_models.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/domain/teaching_assignment.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/domain/teaching_assignments_repository.dart';

class TeachingAssignmentsRepositoryImpl implements TeachingAssignmentsRepository {
  const new({required this._api});

  final ApiClient _api;

  static const _path = 'teaching-assignments';

  @override
  Future<ItemsPage<TeachingAssignment>> assignments(
    String institutionId, {
    required String academicYearId,
    required String staffMemberId,
    int page = 1,
  }) async {
    final answer = await _api.request(
      _path,
      query: {
        'institutionId': institutionId,
        'academicYearId': academicYearId,
        'staffMemberId': staffMemberId,
        'page': page,
      },
      parse: TeachingAssignmentModels.assignments,
    );
    final meta = answer.meta;
    return ItemsPage(answer.data, page: page, totalPages: meta is NumberedPage ? meta.totalPages : page);
  }

  @override
  Future<TeachingAssignment> assign({
    required String staffMemberId,
    required String academicYearId,
    required String sectionId,
    required String subjectId,
  }) => _api.data(
    _path,
    method: HttpMethod.post,
    body: {
      'staffMemberId': staffMemberId,
      'academicYearId': academicYearId,
      'sectionId': sectionId,
      'subjectId': subjectId,
    },
    parse: TeachingAssignmentModels.assignment,
  );

  @override
  Future<void> end(String id) => _api.data(
    '$_path/${Uri.encodeComponent(id)}',
    method: HttpMethod.delete,
    parse: (_) {},
  );
}
