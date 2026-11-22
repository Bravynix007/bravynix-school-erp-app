import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/attendance/data/attendance_models.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  const new({required this._api});

  final ApiClient _api;

  static String _register(String id) => 'attendance/sessions/${Uri.encodeComponent(id)}';

  @override
  Future<MarkingSections> sections(String institutionId) =>
      _api.data('attendance/sections', query: {'institutionId': institutionId}, parse: AttendanceModels.sections);

  @override
  Future<AttendanceRoster> roster(String sectionId, String day) =>
      _api.data('attendance/roster', query: {'sectionId': sectionId, 'date': day}, parse: AttendanceModels.roster);

  @override
  Future<RegisterCounts> submit({
    required String sectionId,
    required String day,
    required int rosterCount,
    required List<MarkChange> exceptions,
    required String idempotencyKey,
  }) => _api.data(
    'attendance/sessions',
    method: HttpMethod.post,
    idempotencyKey: idempotencyKey,
    body: AttendanceModels.submitBody(
      sectionId: sectionId,
      day: day,
      rosterCount: rosterCount,
      exceptions: exceptions,
    ),
    parse: AttendanceModels.counts,
  );

  @override
  Future<RegisterCounts> correct(String registerId, int version, List<MarkChange> changes) => _api.data(
    '${_register(registerId)}/marks',
    method: HttpMethod.patch,
    body: AttendanceModels.correctBody(version, changes),
    parse: AttendanceModels.counts,
  );

  @override
  Future<void> voidRegister(String registerId, int version, String reason) => _api.data(
    '${_register(registerId)}/void',
    method: HttpMethod.post,
    body: {'version': version, 'reason': reason},
    parse: (_) {},
  );
}
