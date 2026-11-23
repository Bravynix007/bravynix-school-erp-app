import 'package:equatable/equatable.dart';

/// A subject or a teacher as a timetable entry names them.
class EntryRef extends Equatable {
  const new({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// The period an entry sits in: its number, times (`HH:MM`) and, when the school named it, its label.
class EntrySlot extends Equatable {
  const new({
    required this.id,
    required this.periodNo,
    required this.startTime,
    required this.endTime,
    this.label,
  });

  final String id;
  final int periodNo;
  final String startTime;
  final String endTime;
  final String? label;

  @override
  List<Object?> get props => [id, periodNo, startTime, endTime, label];
}

/// One lesson or break of a section's week (API design 9.7): a day from 1 (Monday) to 6 (Saturday), a period, and for a
/// lesson its subject and teacher.
class TimetableEntry extends Equatable {
  const new({
    required this.id,
    required this.sectionId,
    required this.dayOfWeek,
    required this.slot,
    required this.isBreak,
    required this.version,
    this.sectionName,
    this.className,
    this.subject,
    this.teacher,
  });

  final String id;
  final String sectionId;

  /// Null for a parent, who reads the week of their child's section and is not told which one it is.
  final String? sectionName;
  final String? className;
  final int dayOfWeek;
  final EntrySlot slot;
  final bool isBreak;

  /// Both are null for a break.
  final EntryRef? subject;
  final EntryRef? teacher;

  /// What a change must send back, so one made meanwhile is told apart (409 VERSION_CONFLICT).
  final int version;

  /// "7th - A", or empty when the entry does not say.
  String get classSection => [className, sectionName].whereType<String>().where((part) => part.isNotEmpty).join(' - ');

  @override
  List<Object?> get props => [
    id,
    sectionId,
    sectionName,
    className,
    dayOfWeek,
    slot,
    isBreak,
    subject,
    teacher,
    version,
  ];
}

/// What an admin sets on an entry (TT-02, TT-03): the day, the period, and for a lesson its subject and teacher. A break
/// names neither.
class EntryInput extends Equatable {
  const new({
    required this.dayOfWeek,
    required this.timeSlotId,
    required this.isBreak,
    this.subjectId,
    this.staffMemberId,
  });

  final int dayOfWeek;
  final String timeSlotId;
  final bool isBreak;
  final String? subjectId;
  final String? staffMemberId;

  @override
  List<Object?> get props => [dayOfWeek, timeSlotId, isBreak, subjectId, staffMemberId];
}
