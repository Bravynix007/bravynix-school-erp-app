import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slot.dart';

/// The period timings of an Institution's current academic year (TTS-01 to TTS-04). Methods throw [ApiFailure].
abstract class TimeSlotsRepository {
  /// TTS-01: the active periods, earliest start first. 422 CURRENT_YEAR_REQUIRED when the Institution has no current
  /// year.
  Future<List<TimeSlot>> slots(String institutionId);

  /// TTS-02: 409 DUPLICATE on the number, 409 TIME_SLOT_OVERLAP when the times overlap another period; a period may end
  /// when the next begins.
  Future<TimeSlot> create(
    String institutionId, {
    required int periodNo,
    required String startTime,
    required String endTime,
    required bool isBreak,
    String? label,
  });

  /// TTS-03: the times and the label, with the version that was read. The number and the break mark stay as they were.
  /// 409 VERSION_CONFLICT when it changed meanwhile.
  Future<TimeSlot> update(TimeSlot slot, {required String startTime, required String endTime, String? label});

  /// TTS-04: deactivates the period; its number and times are free again. 409 TIME_SLOT_IN_USE while a timetable entry
  /// sits in it.
  Future<void> deactivate(String id);
}
