/// The phone's push service: where the app gets the token the server sends alerts to (FCM on both platforms).
abstract class PushMessaging {
  /// This install's token, or null when the phone gives none (no push service, or the person turned alerts off).
  Future<String?> token();

  /// A new token, when the push service changes this install's: the server is told again.
  Stream<String> get tokenRefreshes;
}

/// The phone gives no token until the Firebase driver is added (build plan: Firebase last), so the app registers
/// nothing and alerts reach the inbox only.
class UnavailablePushMessaging implements PushMessaging {
  const new();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();
}
