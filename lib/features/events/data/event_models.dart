import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';

/// JSON → domain for EVT-01 and EVT-03, and domain → body for EVT-02 and EVT-04. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
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
      image: switch (json['image']) {
        final Map<String, dynamic> image => EventImage(id: image['id'] as String, url: image['url'] as String),
        _ => null,
      },
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

  static DateTime _day(Object? value) =>
      Formatters.parseDay(value! as String) ?? (throw FormatException('Not a day: $value'));

  /// Every field the form holds: a field left empty is sent as `null`, which clears it on a change, and a plain event
  /// says no holiday at all, so a holiday that was switched off is cleared whole.
  static Map<String, Object?> fields(EventInput input) => {
    'title': input.title,
    'startDate': Formatters.isoDay(input.startDate),
    'endDate': Formatters.isoDay(input.endDate),
    'durationLabel': input.durationLabel,
    'description': input.description,
    'venue': input.venue,
    'audience': input.audience.code,
    'presetImageCode': input.presetImageCode,
    'imageFileId': input.imageFileId,
    'isHoliday': input.isHoliday,
    'holidayType': input.isHoliday ? input.holidayType?.code : null,
    'holidayForStudents': input.isHoliday && input.holidayForStudents,
    'holidayForStaff': input.isHoliday && input.holidayForStaff,
    'holidayPredefinedClassIds': input.isHoliday && input.holidayForStudents ? input.holidayClassIds : const <String>[],
  };

  static Map<String, Object?> createBody(EventInput input, {required EventScope scope, String? institutionId}) => {
    ...fields(input),
    'scope': scope.code,
    'institutionId': ?institutionId,
  };

  static Map<String, Object?> scopeBody(SchoolEvent event, {required EventScope scope, String? institutionId}) => {
    'version': event.version,
    'scope': scope.code,
    'institutionId': ?institutionId,
  };

  static Map<String, Object?> changeBody(SchoolEvent event, EventInput input) => {
    'version': event.version,
    ...fields(input),
  };
}
