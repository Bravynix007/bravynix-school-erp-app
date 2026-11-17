import 'package:bravynix_school_erp/features/notifications/domain/inbox_item.dart';

InboxItem inboxItem({
  String id = 'n1',
  String title = 'Diya is absent today',
  String body = 'Diya was marked Absent in 7th - A on 17-11-2026.',
  bool isRead = false,
  NotificationCategory category = NotificationCategory.attendance,
  String? sender = 'Green Valley School',
  NotificationTarget? target,
}) => InboxItem(
  id: id,
  createdAt: DateTime.utc(2026, 11, 17, 4, 45),
  category: category,
  title: title,
  body: body,
  isRead: isRead,
  senderDisplayName: sender,
  target: target,
);

Map<String, Object?> inboxItemJson({String id = 'n1', bool isRead = false, Object? target}) => {
  'id': id,
  'createdAt': '2026-11-17T04:45:00.000Z',
  'category': 1,
  'tab': 1,
  'title': 'Diya is absent today',
  'body': 'Diya was marked Absent in 7th - A on 17-11-2026.',
  'senderDisplayName': 'Green Valley School',
  'institutionId': 'i1',
  'studentId': 's1',
  'target': ?target,
  'isRead': isRead,
  'readAt': null,
};
