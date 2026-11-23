import 'dart:async';

import 'package:bravynix_school_erp/features/push/data/firebase_push_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseMessaging extends Mock implements FirebaseMessaging;

NotificationSettings _settings(AuthorizationStatus status) => NotificationSettings(
  alert: AppleNotificationSetting.enabled,
  announcement: AppleNotificationSetting.notSupported,
  authorizationStatus: status,
  badge: AppleNotificationSetting.enabled,
  carPlay: AppleNotificationSetting.notSupported,
  lockScreen: AppleNotificationSetting.enabled,
  notificationCenter: AppleNotificationSetting.enabled,
  showPreviews: AppleShowPreviewSetting.always,
  timeSensitive: AppleNotificationSetting.notSupported,
  criticalAlert: AppleNotificationSetting.notSupported,
  sound: AppleNotificationSetting.enabled,
  providesAppNotificationSettings: AppleNotificationSetting.notSupported,
);

// The registration token is the one the server sends to; see the class comment of the driver.
// ignore_for_file: deprecated_member_use
void main() {
  late _MockFirebaseMessaging messaging;
  late StreamController<RemoteMessage> opened;

  setUp(() {
    messaging = _MockFirebaseMessaging();
    opened = StreamController<RemoteMessage>.broadcast();
  });
  tearDown(() => opened.close());

  FirebasePushMessaging build() => FirebasePushMessaging(messaging, opened.stream);

  group('token', () {
    test('asks the person to allow alerts, then gives the token', () async {
      when(() => messaging.requestPermission()).thenAnswer((_) async => _settings(AuthorizationStatus.authorized));
      when(messaging.getToken).thenAnswer((_) async => 'tok-1');
      expect(await build().token(), 'tok-1');
      verify(() => messaging.requestPermission()).called(1);
    });

    test('gives no token to a person who turned alerts off', () async {
      when(() => messaging.requestPermission()).thenAnswer((_) async => _settings(AuthorizationStatus.denied));
      expect(await build().token(), isNull);
      verifyNever(messaging.getToken);
    });

    test('gives no token while Apple has not given the phone its own', () async {
      when(() => messaging.requestPermission()).thenAnswer((_) async => _settings(AuthorizationStatus.authorized));
      when(messaging.getToken).thenThrow(FirebaseException(plugin: 'firebase_messaging', code: 'apns-token-not-set'));
      expect(await build().token(), isNull);
    });
  });

  test('a token the push service changes is passed on', () async {
    final refreshes = StreamController<String>();
    addTearDown(refreshes.close);
    when(() => messaging.onTokenRefresh).thenAnswer((_) => refreshes.stream);
    final received = expectLater(build().tokenRefreshes, emits('tok-2'));
    refreshes.add('tok-2');
    await received;
  });

  group('the screen an alert asks for', () {
    test('is the one the alert that started the app names', () async {
      when(messaging.getInitialMessage).thenAnswer((_) async => const RemoteMessage(data: {'screen': 'inbox'}));
      expect(await build().launchScreen(), 'inbox');
    });

    test('is none when the app was not started by an alert, or the alert names none', () async {
      when(messaging.getInitialMessage).thenAnswer((_) async => null);
      expect(await build().launchScreen(), isNull);
      when(messaging.getInitialMessage).thenAnswer((_) async => const RemoteMessage());
      expect(await build().launchScreen(), isNull);
    });

    test('is each one a tapped alert names, and alerts that name none are skipped', () async {
      final taps = expectLater(build().screenTaps, emitsInOrder(['inbox', 'inbox']));
      opened
        ..add(const RemoteMessage())
        ..add(const RemoteMessage(data: {'screen': 'inbox'}))
        ..add(const RemoteMessage(data: {'screen': 'inbox'}));
      await taps;
    });
  });
}
