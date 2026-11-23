import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_week.dart';

/// JSON → domain for TT-01. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class TimetableModels {
  static EntryRef? _ref(Object? raw, String name) {
    if (raw == null) return null;
    final json = jsonObject(raw);
    return EntryRef(id: json['id'] as String, name: json[name] as String);
  }

  static EntrySlot _slot(Object? raw) {
    final json = jsonObject(raw);
    return EntrySlot(
      id: json['id'] as String,
      periodNo: (json['periodNo'] as num).toInt(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      label: json['label'] as String?,
    );
  }

  static TimetableEntry entry(Object? raw) {
    final json = jsonObject(raw);
    return TimetableEntry(
      id: json['id'] as String,
      sectionId: json['sectionId'] as String,
      sectionName: json['sectionName'] as String?,
      className: json['className'] as String?,
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      slot: _slot(json['timeSlot']),
      isBreak: json['isBreak'] as bool,
      subject: _ref(json['subject'], 'name'),
      teacher: _ref(json['teacher'], 'displayName'),
      version: (json['version'] as num).toInt(),
    );
  }

  static List<TimetableEntry> entries(Object? raw) => [for (final item in jsonList(raw)) entry(item)];

  /// TT-01 reads exactly one view: a section, a teacher's own week at an Institution, or a parent's child.
  static Map<String, Object?> query(TimetableWeek week) => switch (week) {
    SectionWeek(:final sectionId) => {'sectionId': sectionId},
    OwnWeek(:final institutionId) => {'staffMemberId': 'me', 'institutionId': institutionId},
    ChildWeek(:final studentId) => {'studentId': studentId},
  };

  static Map<String, Object?> _fields(EntryInput input) => {
    'dayOfWeek': input.dayOfWeek,
    'timeSlotId': input.timeSlotId,
    'isBreak': input.isBreak,
    // A break names neither, and the server refuses one that does.
    if (!input.isBreak) ...{'subjectId': input.subjectId, 'staffMemberId': input.staffMemberId},
  };

  static Map<String, Object?> createBody(String sectionId, EntryInput input) => {
    'sectionId': sectionId,
    ..._fields(input),
  };

  static Map<String, Object?> updateBody(TimetableEntry entry, EntryInput input) => {
    'version': entry.version,
    ..._fields(input),
  };
}
