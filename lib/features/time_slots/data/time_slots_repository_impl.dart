import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/time_slots/data/time_slot_models.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slot.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slots_repository.dart';

class TimeSlotsRepositoryImpl implements TimeSlotsRepository {
  const new({required this._api});

  final ApiClient _api;

  static String _path(String id) => 'timetable/time-slots/${Uri.encodeComponent(id)}';

  @override
  Future<List<TimeSlot>> slots(String institutionId) =>
      _api.data('timetable/time-slots', query: {'institutionId': institutionId}, parse: TimeSlotModels.slots);

  @override
  Future<TimeSlot> create(
    String institutionId, {
    required int periodNo,
    required String startTime,
    required String endTime,
    required bool isBreak,
    String? label,
  }) => _api.data(
    'timetable/time-slots',
    method: HttpMethod.post,
    body: TimeSlotModels.createBody(
      institutionId,
      periodNo: periodNo,
      startTime: startTime,
      endTime: endTime,
      isBreak: isBreak,
      label: label,
    ),
    parse: TimeSlotModels.slot,
  );

  @override
  Future<TimeSlot> update(TimeSlot slot, {required String startTime, required String endTime, String? label}) =>
      _api.data(
        _path(slot.id),
        method: HttpMethod.patch,
        body: TimeSlotModels.updateBody(slot, startTime: startTime, endTime: endTime, label: label),
        parse: TimeSlotModels.slot,
      );

  @override
  Future<void> deactivate(String id) => _api.data(_path(id), method: HttpMethod.delete, parse: (_) {});
}
