import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';

/// JSON → domain for ATT-01, ATT-02, ATT-05 and ATT-09. Unknown fields are ignored, as /v1 only ever adds fields (API
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
            SectionChoice(
              id: jsonObject(section)['id'] as String,
              name: '${json['className']} · ${jsonObject(section)['displayName']}',
              classId: json['classId'] as String,
            ),
      ],
    );
  }

  static RosterStudent _student(Object? raw) {
    final json = jsonObject(raw);
    final code = (json['attendanceStatus'] as num).toInt();
    return RosterStudent(
      studentId: json['studentId'] as String,
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

  static RegisterCounts counts(Object? raw) {
    final json = jsonObject(raw);
    int count(String key) => (json[key] as num).toInt();
    return RegisterCounts(
      id: json['id'] as String,
      version: count('version'),
      rosterCount: count('rosterCount'),
      presentCount: count('presentCount'),
      absentCount: count('absentCount'),
      lateCount: count('lateCount'),
      halfDayCount: count('halfDayCount'),
      leaveCount: count('leaveCount'),
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
