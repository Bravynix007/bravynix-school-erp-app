import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';

/// JSON → domain for EVT-01 and EVT-03. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class EventModels {
  static SchoolEvent event(Object? raw) {
    final json = jsonObject(raw);
    return SchoolEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      venue: json['venue'] as String?,
      startDate: _day(json['startDate']),
      endDate: _day(json['endDate']),
      durationLabel: json['durationLabel'] as String,
      audience: EventAudience.fromCode(json['audience']) ?? (throw const FormatException('Unknown audience')),
      scope: EventScope.fromCode(json['scope']) ?? (throw const FormatException('Unknown scope')),
      institutionId: json['institutionId'] as String?,
      presetImageCode: json['presetImageCode'] as String?,
      isHoliday: json['isHoliday'] as bool,
      holidayType: HolidayType.fromCode(json['holidayType']),
      holidayForStudents: json['holidayForStudents'] as bool? ?? false,
      holidayForStaff: json['holidayForStaff'] as bool? ?? false,
      holidayClassIds: [for (final id in jsonList(json['holidayPredefinedClassIds'] ?? const [])) id as String],
      canEdit: json['canEdit'] as bool? ?? false,
      version: (json['version'] as num).toInt(),
    );
  }

  static List<SchoolEvent> events(Object? raw) => [for (final entry in jsonList(raw)) event(entry)];

  /// `2026-11-17`, with no time zone shift.
  static DateTime _day(Object? value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value! as String);
    if (match == null) throw FormatException('Not a day: $value');
    return DateTime(int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!));
  }
}
