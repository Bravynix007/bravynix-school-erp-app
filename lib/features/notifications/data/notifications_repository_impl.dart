import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_envelope.dart';
import 'package:bravynix_school_erp/features/notifications/data/notification_models.dart';
import 'package:bravynix_school_erp/features/notifications/domain/inbox_item.dart';
import 'package:bravynix_school_erp/features/notifications/domain/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const new({required this._api});

  final ApiClient _api;

  @override
  Future<InboxPage> inbox(InboxTab tab, {String? cursor}) async {
    final answer = await _api.request(
      'notifications',
      query: {'tab': tab.code, 'cursor': cursor},
      parse: NotificationModels.items,
    );
    final meta = answer.meta;
    return InboxPage(answer.data, nextCursor: meta is CursorPage && meta.hasMore ? meta.nextCursor : null);
  }

  @override
  Future<int> unreadCount() => _api.data('notifications/unread-count', parse: NotificationModels.count);

  @override
  Future<InboxItem> markRead(String id) => _api.data(
    'notifications/${Uri.encodeComponent(id)}/read',
    method: HttpMethod.post,
    parse: NotificationModels.item,
  );

  @override
  Future<void> markAllRead({InboxTab? tab}) => _api.data(
    'notifications/read-all',
    method: HttpMethod.post,
    query: {'tab': tab?.code},
    parse: (_) {},
  );

  @override
  Future<void> clear({InboxTab? tab}) => _api.data(
    'notifications',
    method: HttpMethod.delete,
    query: {'tab': tab?.code},
    parse: (_) {},
  );
}
