import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/notifications/domain/inbox_item.dart';

/// The person's inbox (API design 10.4h). Methods throw [ApiFailure]. Every context sees its own notices, and a block
/// does not stop it.
abstract class NotificationsRepository {
  /// NTF-01: a page of one tab, newest first; [cursor] is the one the page before answered.
  Future<InboxPage> inbox(InboxTab tab, {String? cursor});

  /// NTF-02: how many are unread, 10 at most (the bell shows "9+").
  Future<int> unreadCount();

  /// NTF-03: marks one read.
  Future<InboxItem> markRead(String id);

  /// NTF-04: marks every unread one of [tab] read, or of every tab when none is named.
  Future<void> markAllRead({InboxTab? tab});

  /// NTF-05: deletes the person's own notices of [tab], or of every tab when none is named.
  Future<void> clear({InboxTab? tab});
}
