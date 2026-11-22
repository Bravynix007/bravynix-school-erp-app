import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/notifications/domain/inbox_item.dart';

/// JSON → domain for NTF-01 to NTF-05. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class NotificationModels {
  static InboxItem item(Object? raw) {
    final json = jsonObject(raw);
    final target = json['target'];
    final type = target is Map<String, dynamic> ? NotificationTargetType.fromCode(target['type']) : null;
    return InboxItem(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: NotificationCategory.fromCode(json['category']),
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      senderDisplayName: json['senderDisplayName'] as String?,
      institutionId: json['institutionId'] as String?,
      studentId: json['studentId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      target: type == null
          ? null
          : NotificationTarget(type: type, id: (target! as Map<String, dynamic>)['id'] as String),
    );
  }

  static List<InboxItem> items(Object? raw) => [for (final entry in jsonList(raw)) item(entry)];

  /// `{ count }` of NTF-02.
  static int count(Object? raw) => (jsonObject(raw)['count'] as num).toInt();
}
