/// The phone's push service: where the app gets the token the server sends alerts to (FCM on both platforms), and
/// which screen an alert the person taps asks to open.
abstract class PushMessaging {
  /// This install's token, or null when the phone gives none (no push service, or the person turned alerts off).
  Future<String?> token();

  /// A new token, when the push service changes this install's: the server is told again.
  Stream<String> get tokenRefreshes;

  /// The screen named by the alert the person tapped to start the app, or null when it was not started by an alert.
  Future<String?> launchScreen();

  /// The screen named by an alert the person taps while the app is running in the background.
  Stream<String> get screenTaps;
}

/// The phone gives no token where Firebase is not set up (the web build, a build without the Firebase files, tests),
/// so the app registers nothing and alerts reach the inbox only.
class UnavailablePushMessaging implements PushMessaging {
  const new();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Future<String?> launchScreen() async => null;

  @override
  Stream<String> get screenTaps => const Stream.empty();
}
