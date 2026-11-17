import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/notifications/data/notifications_repository_impl.dart';
import 'package:bravynix_school_erp/features/notifications/domain/inbox_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/notifications.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({NotificationsRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: NotificationsRepositoryImpl(api: api), adapter: adapter);
  }

  test('reads a tab of the inbox, with the cursor for the next page', () async {
    final (:repository, :adapter) = build(
      () => okReply(
        [
          inboxItemJson(target: {'type': 1, 'id': 'a1'}),
          inboxItemJson(id: 'n2', isRead: true, target: {'type': 99, 'id': 'x'}),
        ],
        meta: {'limit': 20, 'nextCursor': 'c2', 'hasMore': true},
      ),
    );
    final page = await repository.inbox(InboxTab.allStudents, cursor: 'c1');
    expect(adapter.requests.single.uri.queryParameters, {'tab': '4', 'cursor': 'c1'});
    expect(page.nextCursor, 'c2');
    expect(page.items.first.target, const NotificationTarget(type: NotificationTargetType.attendance, id: 'a1'));
    expect(page.items.first.category, NotificationCategory.attendance);
    expect(page.items.first.senderDisplayName, 'Green Valley School');
    expect(page.items.last.isRead, isTrue);
    // A target this app version does not know cannot be opened.
    expect(page.items.last.target, isNull);
  });

  test('the last page has no cursor', () async {
    final (:repository, adapter: _) = build(
      () => okReply([inboxItemJson()], meta: {'limit': 20, 'nextCursor': null, 'hasMore': false}),
    );
    final page = await repository.inbox(InboxTab.onlyForYou);
    expect(page.hasMore, isFalse);
  });

  test('reads the unread count', () async {
    final (:repository, :adapter) = build(() => okReply({'count': 7}));
    expect(await repository.unreadCount(), 7);
    expect(adapter.paths, ['/v1/notifications/unread-count']);
  });

  test('marks one read, encoding its ID, and answers the item', () async {
    final (:repository, :adapter) = build(() => okReply(inboxItemJson(id: 'a/b', isRead: true)));
    final read = await repository.markRead('a/b');
    expect(read.isRead, isTrue);
    expect(adapter.paths, ['/v1/notifications/a%2Fb/read']);
    expect(adapter.requests.single.method, 'POST');
  });

  test('marks a tab read, or every tab when none is named', () async {
    final (:repository, :adapter) = build(() => okReply({'updated': 3}));
    await repository.markAllRead(tab: InboxTab.all);
    await repository.markAllRead();
    expect(adapter.requests.map((request) => request.uri.toString()), [
      'http://api.test/v1/notifications/read-all?tab=2',
      'http://api.test/v1/notifications/read-all',
    ]);
  });

  test('clears a tab with DELETE', () async {
    final (:repository, :adapter) = build(() => okReply({'deleted': 3}));
    await repository.clear(tab: InboxTab.onlyForYou);
    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.uri.queryParameters, {'tab': '1'});
  });
}
