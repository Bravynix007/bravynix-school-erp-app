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

/// The picture an organiser uploaded for an event: the file's ID, which a change sends back to keep it, and its public
/// address, which anyone the event is shown to can open without signing in (API design 15.1).
class EventImage extends Equatable {
  const new({required this.id, required this.url});

  final String id;
  final String url;

  @override
  List<Object?> get props => [id, url];
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
    this.image,
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

  /// The event's own picture; never together with [presetImageCode].
  final EventImage? image;
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
    image,
    isHoliday,
    holidayType,
    holidayForStudents,
    holidayForStaff,
    holidayClassIds,
    canEdit,
    version,
  ];
}

/// What the form of an event holds once it is complete: EVT-02 sends all of it, EVT-04 sends all of it with the version
/// that was read. The scope is chosen when the event is created and changed by its own action (EVT-06).
class EventInput extends Equatable {
  const new({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.durationLabel,
    required this.audience,
    this.description,
    this.venue,
    this.presetImageCode,
    this.imageFileId,
    this.isHoliday = false,
    this.holidayType,
    this.holidayForStudents = false,
    this.holidayForStaff = false,
    this.holidayClassIds = const [],
  });

  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String durationLabel;
  final EventAudience audience;
  final String? description;
  final String? venue;
  final String? presetImageCode;

  /// The uploaded picture, a Ready Event image; at most one of this and [presetImageCode].
  final String? imageFileId;
  final bool isHoliday;
  final HolidayType? holidayType;
  final bool holidayForStudents;
  final bool holidayForStaff;

  /// The predefined classes a holiday for students is for; empty is every class.
  final List<String> holidayClassIds;

  @override
  List<Object?> get props => [
    title,
    startDate,
    endDate,
    durationLabel,
    audience,
    description,
    venue,
    presetImageCode,
    imageFileId,
    isHoliday,
    holidayType,
    holidayForStudents,
    holidayForStaff,
    holidayClassIds,
  ];
}
