import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_envelope.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/students/data/student_models.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/student_draft.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';

class StudentsRepositoryImpl implements StudentsRepository {
  const new({required this._api});

  final ApiClient _api;

  @override
  Future<ItemsPage<StudentSummary>> students(
    String institutionId, {
    int page = 1,
    String query = '',
    StudentFilter filter = const StudentFilter(),
  }) async {
    final answer = await _api.request(
      'students',
      query: {
        'institutionId': institutionId,
        'page': page,
        'q': query.isEmpty ? null : query,
        'academicYearId': filter.academicYearId,
        'classId': filter.classId,
        'sectionId': filter.sectionId,
      },
      parse: StudentModels.summaries,
    );
    // An answer without page numbers is the whole list.
    final meta = answer.meta;
    return ItemsPage(answer.data, page: page, totalPages: meta is NumberedPage ? meta.totalPages : page);
  }

  @override
  Future<void> deactivate(String id, LeavingReason reason) => _api.data(
    'students/${Uri.encodeComponent(id)}',
    method: HttpMethod.delete,
    query: {'reason': reason.code},
    parse: (_) {},
  );

  @override
  Future<List<String>> move(String id, {String? sectionId, String? rollNumber, String? effectiveDate}) async {
    final answer = await _api.request(
      'students/${Uri.encodeComponent(id)}/placement',
      method: HttpMethod.patch,
      body: {'sectionId': ?sectionId, 'rollNumber': ?rollNumber, 'effectiveDate': ?effectiveDate},
      parse: (_) {},
    );
    return answer.warnings;
  }

  @override
  Future<StudentSaved> create(
    String institutionId,
    StudentDraft draft, {
    required EnrolmentDraft enrolment,
    required List<GuardianDraft> guardians,
    IdentityDraft identity = const IdentityDraft(),
  }) async {
    final answer = await _api.request(
      'students',
      method: HttpMethod.post,
      body: StudentModels.createBody(institutionId, draft, enrolment, guardians, identity),
      parse: StudentModels.student,
    );
    return StudentSaved(answer.data, warnings: answer.warnings);
  }
}
