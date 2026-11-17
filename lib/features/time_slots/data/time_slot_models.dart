import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slot.dart';

/// JSON → domain for TTS-01 to TTS-03. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class TimeSlotModels {
  static TimeSlot slot(Object? raw) {
    final json = jsonObject(raw);
    return TimeSlot(
      id: json['id'] as String,
      institutionId: json['institutionId'] as String,
      academicYearId: json['academicYearId'] as String,
      periodNo: (json['periodNo'] as num).toInt(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      isBreak: json['isBreak'] as bool,
      label: json['label'] as String?,
      version: (json['version'] as num).toInt(),
    );
  }

  static List<TimeSlot> slots(Object? raw) => [for (final item in jsonList(raw)) slot(item)];

  /// TTS-02: a period without a label sends none, and the year is the current one.
  static Map<String, Object?> createBody(
    String institutionId, {
    required int periodNo,
    required String startTime,
    required String endTime,
    required bool isBreak,
    String? label,
  }) => {
    'institutionId': institutionId,
    'periodNo': periodNo,
    'startTime': startTime,
    'endTime': endTime,
    'isBreak': isBreak,
    'label': ?label,
  };

  /// TTS-03: the three editable fields and the version that was read; `null` clears the label.
  static Map<String, Object?> updateBody(
    TimeSlot slot, {
    required String startTime,
    required String endTime,
    String? label,
  }) => {'version': slot.version, 'startTime': startTime, 'endTime': endTime, 'label': label};
}
