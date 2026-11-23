import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:equatable/equatable.dart';

/// The tabs of the inbox (API design 10.4h, PRD 7.17).
enum InboxTab {
  onlyForYou(1),
  all(2),
  allTeachers(3),
  allStudents(4);

  new(this.code);

  final int code;

  /// The tabs a role sees (PRD 7.17): the Owner and the Admins all four, a teacher no students' tab, a parent no
  /// teachers' tab. Before a role is chosen only the two every role has.
  static List<InboxTab> of(RoleCode? role) => switch (role) {
    RoleCode.superAdmin || RoleCode.societyOwner || RoleCode.institutionAdmin => values,
    RoleCode.teacherStaff => const [onlyForYou, all, allTeachers],
    RoleCode.studentParent => const [onlyForYou, all, allStudents],
    null => const [onlyForYou, all],
  };
}

/// What a notice is about, so the app can open it (API design 10.4h). Types the app does not know are not openable.
enum NotificationTargetType {
  attendance(1),
  diary(2),
  event(3);

  new(this.code);

  final int code;

  static NotificationTargetType? fromCode(Object? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

class NotificationTarget extends Equatable {
  const new({required this.type, required this.id, this.day});

  final NotificationTargetType type;
  final String id;

  /// The day the screen opens on (`YYYY-MM-DD`), for a notice about a day: the date of a diary entry.
  final String? day;

  @override
  List<Object?> get props => [type, id, day];
}

/// What kind of notice it is, for its icon: attendance, diary, event, or anything else the server adds (API design 5.2).
enum NotificationCategory {
  attendance(1),
  diary(2),
  event(3),
  other(0);

  new(this.code);

  final int code;

  static NotificationCategory fromCode(Object? code) {
    for (final category in values) {
      if (category.code == code) return category;
    }
    return other;
  }
}

/// One notice in the person's inbox (NTF-01).
class InboxItem extends Equatable {
  const new({
    required this.id,
    required this.createdAt,
    required this.category,
    required this.title,
    required this.body,
    required this.isRead,
    this.senderDisplayName,
    this.institutionId,
    this.studentId,
    this.target,
  });

  final String id;
  final DateTime createdAt;
  final NotificationCategory category;
  final String title;
  final String body;
  final String? senderDisplayName;

  /// The Institution the notice comes from, and for a guardian the child it is about; null when it is for no one child.
  final String? institutionId;
  final String? studentId;

  /// Null for a notice that is only to read, or about something this app version cannot open.
  final NotificationTarget? target;
  final bool isRead;

  @override
  List<Object?> get props => [
    id,
    createdAt,
    category,
    title,
    body,
    senderDisplayName,
    institutionId,
    studentId,
    target,
    isRead,
  ];
}

/// One page of the inbox, newest first, read by cursor (API design 7.5).
class InboxPage extends Equatable {
  const new(this.items, {this.nextCursor});

  final List<InboxItem> items;

  /// Null on the last page.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [items, nextCursor];
}
