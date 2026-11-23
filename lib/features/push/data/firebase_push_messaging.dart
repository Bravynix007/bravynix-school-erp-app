import 'dart:developer';

import 'package:bravynix_school_erp/features/push/domain/push_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging on Android and iOS (SDD 18). The server sends through the FCM HTTP v1 API to registration
/// tokens, which `getToken` and `onTokenRefresh` give; the newer `register()` / `onRegistered` hand out an installation
/// ID for direct send instead, which the server does not use, so the two older calls stay until it does. Asking for
/// the token asks the person to allow alerts first (Android 13 and iOS); a person who says no gets no token, and their alerts reach the inbox only.
class FirebasePushMessaging implements PushMessaging {
  const new(this._messaging, this._opened);

  /// Starts Firebase from the files of the build and answers the driver, or [UnavailablePushMessaging] when this
  /// build has none (the web build, or no `google-services.json` / `GoogleService-Info.plist` beside the code).
  static Future<PushMessaging> start() async {
    if (kIsWeb) return const UnavailablePushMessaging();
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      // An alert that arrives while the app is open still shows on iOS; Android shows it from the background only.
      await messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      return FirebasePushMessaging(messaging, FirebaseMessaging.onMessageOpenedApp);
    } on Object catch (error) {
      log('Firebase is not set up in this build', name: 'push', error: error);
      return const UnavailablePushMessaging();
    }
  }

  final FirebaseMessaging _messaging;
  final Stream<RemoteMessage> _opened;

  @override
  Future<String?> token() async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return null;
      // ignore: deprecated_member_use, the registration token the server sends to (see the class comment).
      return await _messaging.getToken();
    } on FirebaseException catch (error) {
      // iOS has no token until Apple has given the phone its own (no APNs key, or a simulator).
      log('No push token', name: 'push', error: error.code);
      return null;
    }
  }

  @override
  // ignore: deprecated_member_use, the registration token the server sends to (see the class comment).
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Future<String?> launchScreen() async => _screenOf(await _messaging.getInitialMessage());

  @override
  Stream<String> get screenTaps => _opened.map(_screenOf).where((screen) => screen != null).cast<String>();

  String? _screenOf(RemoteMessage? message) => message?.data['screen'] as String?;
}
