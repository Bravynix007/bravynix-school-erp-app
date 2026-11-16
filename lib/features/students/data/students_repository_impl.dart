import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_envelope.dart';
import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/students/data/student_models.dart';
import 'package:bravynix_school_erp/features/students/domain/promotion.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/student_draft.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
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
  Future<StudentRecord> student(String id) =>
      _api.data('students/${Uri.encodeComponent(id)}', parse: StudentModels.record);

  @override
  Future<StudentRecord> update(String id, int version, StudentDraft draft) => _api.data(
    'students/${Uri.encodeComponent(id)}',
    method: HttpMethod.patch,
    body: StudentModels.updateBody(draft, version),
    parse: StudentModels.record,
  );

  @override
  Future<StudentRecord> block(String id) =>
      _api.data('students/${Uri.encodeComponent(id)}/block', method: HttpMethod.post, parse: StudentModels.record);

  @override
  Future<StudentRecord> unblock(String id) =>
      _api.data('students/${Uri.encodeComponent(id)}/unblock', method: HttpMethod.post, parse: StudentModels.record);

  Future<IdentitySaved> _setIdentity(String id, Map<String, Object?> body) async {
    final answer = await _api.request(
      'students/${Uri.encodeComponent(id)}/identity',
      method: HttpMethod.put,
      body: body,
      parse: StudentModels.identity,
    );
    return IdentitySaved(answer.data, warnings: answer.warnings);
  }

  @override
  Future<IdentitySaved> setAadhaar(String id, String? aadhaar) => _setIdentity(id, {'aadhaarNumber': aadhaar});

  @override
  Future<IdentitySaved> setBirthCertificate(String id, String? number) =>
      _setIdentity(id, {'birthCertificateNumber': number});

  @override
  Future<String> revealAadhaar(String id, {required String reason}) => _api.data(
    'students/${Uri.encodeComponent(id)}/identity/reveal',
    method: HttpMethod.post,
    body: {'field': 'aadhaar', 'reason': reason},
    parse: (raw) => jsonObject(raw)['value'] as String,
  );

  @override
  Future<Promoted> promoteStudent(String id, {PromotionTarget? target, String? rollNumber}) async {
    final answer = await _api.request(
      'students/${Uri.encodeComponent(id)}/promote',
      method: HttpMethod.post,
      body: {...StudentModels.promotionTarget(target), 'rollNumber': ?rollNumber},
      parse: StudentModels.record,
    );
    return Promoted(answer.data, warnings: answer.warnings);
  }

  @override
  Future<PromotionResult> promote({
    required String institutionId,
    required String fromAcademicYearId,
    required String fromClassId,
    required String idempotencyKey,
    String? fromSectionId,
    PromotionTarget? target,
    bool keepRollNumbers = true,
  }) async {
    final answer = await _api.request(
      'promotions',
      method: HttpMethod.post,
      idempotencyKey: idempotencyKey,
      body: {
        'institutionId': institutionId,
        'fromAcademicYearId': fromAcademicYearId,
        'fromClassId': fromClassId,
        // `null` is an answer, a missing key is not: it means every section.
        'fromSectionId': fromSectionId,
        ...StudentModels.promotionTarget(target),
        'keepRollNumbers': keepRollNumbers,
      },
      parse: StudentModels.promotionResult,
    );
    return PromotionResult(
      promotedCount: answer.data.promotedCount,
      skipped: answer.data.skipped,
      warnings: answer.warnings,
    );
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
  Future<List<String>> correctClass(
    String id, {
    required String classId,
    required String sectionId,
    String? rollNumber,
  }) async {
    final answer = await _api.request(
      'students/${Uri.encodeComponent(id)}/class',
      method: HttpMethod.patch,
      body: {'classId': classId, 'sectionId': sectionId, 'rollNumber': ?rollNumber},
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
