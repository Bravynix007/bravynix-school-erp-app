import 'package:equatable/equatable.dart';

/// Who an event is told to (API design 10.26).
enum EventAudience {
  everyone(1),
  studentsAndParents(2),
  staff(3);

  new(this.code);

  final int code;

  static EventAudience? fromCode(Object? code) {
    for (final audience in values) {
      if (audience.code == code) return audience;
    }
    return null;
  }
}

/// Whether an event belongs to the whole Society or to one Institution.
enum EventScope {
  society(1),
  institution(2);

  new(this.code);

  final int code;

  static EventScope? fromCode(Object? code) {
    for (final scope in values) {
      if (scope.code == code) return scope;
    }
    return null;
  }
}

/// The kinds of holiday (PRD 11.4).
enum HolidayType {
  publicHoliday(1),
  vacation(2),
  eventHoliday(3),
  optional(4);

  new(this.code);

  final int code;

  static HolidayType? fromCode(Object? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

/// One event or holiday (EVT-01, EVT-03). The days are school days, with no time zone.
class SchoolEvent extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.durationLabel,
    required this.audience,
    required this.scope,
    required this.isHoliday,
    required this.holidayForStudents,
    required this.holidayForStaff,
    required this.canEdit,
    required this.version,
    this.description,
    this.venue,
    this.institutionId,
    this.presetImageCode,
    this.holidayType,
    this.holidayClassIds = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String? venue;
  final DateTime startDate;
  final DateTime endDate;

  /// What the creator wrote: "3 Days Holiday".
  final String durationLabel;
  final EventAudience audience;
  final EventScope scope;

  /// Set exactly when [scope] is an Institution.
  final String? institutionId;
  final String? presetImageCode;
  final bool isHoliday;
  final HolidayType? holidayType;
  final bool holidayForStudents;
  final bool holidayForStaff;

  /// The predefined classes a holiday is for; empty is every class.
  final List<String> holidayClassIds;

  /// Whether the person sees Edit and Delete on it.
  final bool canEdit;
  final int version;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    venue,
    startDate,
    endDate,
    durationLabel,
    audience,
    scope,
    institutionId,
    presetImageCode,
    isHoliday,
    holidayType,
    holidayForStudents,
    holidayForStaff,
    holidayClassIds,
    canEdit,
    version,
  ];
}
