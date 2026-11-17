import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/notifications/domain/inbox_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each role sees the tabs of PRD 7.17', () {
    expect(InboxTab.of(RoleCode.societyOwner), InboxTab.values);
    expect(InboxTab.of(RoleCode.institutionAdmin), InboxTab.values);
    expect(InboxTab.of(RoleCode.teacherStaff), [InboxTab.onlyForYou, InboxTab.all, InboxTab.allTeachers]);
    expect(InboxTab.of(RoleCode.studentParent), [InboxTab.onlyForYou, InboxTab.all, InboxTab.allStudents]);
    expect(InboxTab.of(null), [InboxTab.onlyForYou, InboxTab.all]);
  });

  test('a category the app does not know is shown as other', () {
    expect(NotificationCategory.fromCode(2), NotificationCategory.diary);
    expect(NotificationCategory.fromCode(9), NotificationCategory.other);
  });
}
