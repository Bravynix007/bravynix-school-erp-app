import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_envelope.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/classroom/data/classroom_models.dart';
import 'package:bravynix_school_erp/features/classroom/domain/classroom.dart';

class ClassroomRepositoryImpl implements ClassroomRepository {
  const new({required this._api});

  final ApiClient _api;

  @override
  Future<ItemsPage<ClassroomStudent>> students(String institutionId, {int page = 1, String query = ''}) async {
    final answer = await _api.request(
      'students',
      query: {'institutionId': institutionId, 'page': page, 'q': query.isEmpty ? null : query},
      parse: ClassroomModels.students,
    );
    // An answer without page numbers is the whole list.
    final meta = answer.meta;
    return ItemsPage(answer.data, page: page, totalPages: meta is NumberedPage ? meta.totalPages : page);
  }

  @override
  Future<ClassroomStudent> student(String id) =>
      _api.data('students/${Uri.encodeComponent(id)}', parse: ClassroomModels.student);
}
