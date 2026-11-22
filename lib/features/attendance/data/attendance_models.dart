import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_calendar.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';

/// JSON → domain for ATT-01, ATT-02, ATT-05, ATT-07, ATT-08 and ATT-09. Unknown fields are ignored, as /v1 only ever adds fields (API
/// design 5.2).
abstract final class AttendanceModels {
  static MarkingSections sections(Object? raw) {
    final classes = [for (final item in jsonList(raw)) jsonObject(item)];
    return MarkingSections(
      classes: [
        for (final json in classes) ClassChoice(id: json['classId'] as String, name: json['className'] as String),
      ],
      sections: [
        for (final json in classes)
          for (final section in jsonList(json['sections']))
            SectionChoice.inClass(
              id: jsonObject(section)['id'] as String,
              className: json['className'] as String,
              sectionName: jsonObject(section)['displayName'] as String,
              classId: json['classId'] as String,
            ),
      ],
    );
  }

  static RosterStudent _student(Object? raw) {
    final json = jsonObject(raw);
    final code = (json['attendanceStatus'] as num).toInt();
    return RosterStudent(
      enrolmentId: json['studentEnrolmentId'] as String,
      rollNumber: json['rollNumber'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      // A status the app does not know would be shown as a wrong mark; refuse the answer rather than show it.
      mark: AttendanceMarkCode.fromCode(code) ?? (throw FormatException('Unknown attendance status $code')),
    );
  }

  static TakenRegister? _taken(Object? raw) {
    if (raw == null) return null;
    final json = jsonObject(raw);
    return TakenRegister(
      id: json['id'] as String,
      version: (json['version'] as num).toInt(),
      takenBy: jsonObject(json['submittedBy'])['displayName'] as String,
      takenAt: DateTime.parse(json['submittedAt'] as String),
    );
  }

  static AttendanceRoster roster(Object? raw) {
    final json = jsonObject(raw);
    return AttendanceRoster(
      sectionId: jsonObject(json['section'])['id'] as String,
      day: json['date'] as String,
      isHoliday: json['isHoliday'] as bool,
      holidayTitle: json['holidayTitle'] as String?,
      canMark: json['canMark'] as bool,
      taken: _taken(json['existingSession']),
      students: [for (final item in jsonList(json['students'])) _student(item)],
    );
  }

  /// ATT-02: the number of students the register counts.
  static int rosterCount(Object? raw) => (jsonObject(raw)['rosterCount'] as num).toInt();

  static DayStatus _status(String code) {
    // A status the app does not know would be drawn as another day; refuse the answer rather than show it.
    return DayStatus.fromCode(code) ?? (throw FormatException('Unknown day status $code'));
  }

  static CalendarDay _day(Map<String, dynamic> json) => CalendarDay(
    day: json['date'] as String,
    status: _status(json['dayStatus'] as String),
    isWeekend: json['isWeekend'] as bool,
    holidayTitle: json['holidayTitle'] as String?,
  );

  static AttendanceCalendar calendar(Object? raw) {
    final json = jsonObject(raw);
    final summary = jsonObject(json['summary']);
    int count(String key) => (summary[key] as num).toInt();
    return AttendanceCalendar(
      month: json['month'] as String,
      summary: MonthSummary(
        presentDays: count('presentDays'),
        absentDays: count('absentDays'),
        lateDays: count('lateDays'),
        halfDays: count('halfDays'),
        leaveDays: count('leaveDays'),
        holidays: count('holidays'),
        notMarkedDays: count('notMarkedDays'),
        percentage: (summary['attendancePercentage'] as num?)?.toDouble(),
      ),
      yearToDatePercentage: (jsonObject(json['yearToDate'])['attendancePercentage'] as num?)?.toDouble(),
      days: [for (final item in jsonList(json['days'])) _day(jsonObject(item))],
    );
  }

  static DayDetail dayDetail(Object? raw) {
    final json = jsonObject(raw);
    final day = _day(json);
    final section = json['section'];
    final markedBy = json['markedBy'];
    final markedAt = json['markedAt'] as String?;
    final corrected = json['lastCorrectedAt'] as String?;
    return DayDetail(
      day: day.day,
      status: day.status,
      isWeekend: day.isWeekend,
      holidayTitle: day.holidayTitle,
      section: section == null
          ? null
          : DaySection(
              id: jsonObject(section)['id'] as String,
              name: jsonObject(section)['name'] as String?,
              className: jsonObject(section)['className'] as String?,
            ),
      markedBy: markedBy == null ? null : jsonObject(markedBy)['displayName'] as String,
      markedAt: markedAt == null ? null : DateTime.parse(markedAt),
      lastCorrectedAt: corrected == null ? null : DateTime.parse(corrected),
    );
  }

  static Map<String, Object?> _mark(MarkChange change) => {
    'studentEnrolmentId': change.enrolmentId,
    'attendanceStatus': change.mark.code,
  };

  static Map<String, Object?> submitBody({
    required String sectionId,
    required String day,
    required int rosterCount,
    required List<MarkChange> exceptions,
  }) => {
    'sectionId': sectionId,
    'attendanceDate': day,
    'rosterCount': rosterCount,
    'exceptions': [for (final change in exceptions) _mark(change)],
  };

  static Map<String, Object?> correctBody(int version, List<MarkChange> changes) => {
    'version': version,
    'changes': [for (final change in changes) _mark(change)],
  };
}
