import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Words and icons for the parts of an event, shared by the list and the detail.
abstract final class EventText {
  static String audience(AppLocalizations l10n, EventAudience audience) => switch (audience) {
    EventAudience.everyone => l10n.eventAudienceEveryone,
    EventAudience.studentsAndParents => l10n.eventAudienceStudents,
    EventAudience.staff => l10n.eventAudienceStaff,
  };

  static String scope(AppLocalizations l10n, EventScope scope) => switch (scope) {
    EventScope.society => l10n.eventScopeSociety,
    EventScope.institution => l10n.eventScopeInstitution,
  };

  static String holidayType(AppLocalizations l10n, HolidayType type) => switch (type) {
    HolidayType.publicHoliday => l10n.eventHolidayPublic,
    HolidayType.vacation => l10n.eventHolidayVacation,
    HolidayType.eventHoliday => l10n.eventHolidayEvent,
    HolidayType.optional => l10n.eventHolidayOptional,
  };

  static String presetName(AppLocalizations l10n, String? code) => switch (code) {
    'assembly' => l10n.eventPictureAssembly,
    'celebration' => l10n.eventPictureCelebration,
    'cultural' => l10n.eventPictureCultural,
    'exam' => l10n.eventPictureExam,
    'festival' => l10n.eventPictureFestival,
    'holiday' => l10n.eventPictureHoliday,
    'meeting' => l10n.eventPictureMeeting,
    'science' => l10n.eventPictureScience,
    'sports' => l10n.eventPictureSports,
    'trip' => l10n.eventPictureTrip,
    _ => l10n.eventPictureNone,
  };

  /// "17-11-2026", or "17-11-2026 to 19-11-2026" for an event of several days.
  static String days(AppLocalizations l10n, SchoolEvent event) {
    final start = Formatters.schoolDate(Formatters.isoDay(event.startDate));
    final end = Formatters.schoolDate(Formatters.isoDay(event.endDate));
    return start == end ? l10n.eventOneDay(start) : l10n.eventDays(start, end);
  }

  /// The pictures an event can be given without uploading one, by the code the server takes (API design 10.26).
  static const Map<String, IconData> presetIcons = {
    'assembly': Icons.groups_outlined,
    'celebration': Icons.celebration_outlined,
    'cultural': Icons.theater_comedy_outlined,
    'exam': Icons.edit_note_outlined,
    'festival': Icons.festival_outlined,
    'holiday': Icons.beach_access_outlined,
    'meeting': Icons.handshake_outlined,
    'science': Icons.science_outlined,
    'sports': Icons.sports_soccer_outlined,
    'trip': Icons.directions_bus_outlined,
  };

  /// The picture of an event that has none of its own: the preset it was given, else a calendar.
  static IconData icon(SchoolEvent event) =>
      presetIcons[event.presetImageCode] ?? (event.isHoliday ? Icons.beach_access_outlined : Icons.event_outlined);
}
