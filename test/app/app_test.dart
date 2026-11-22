import 'dart:async';

import 'package:bravynix_school_erp/app/app.dart';
import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/storage/install_marker.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/push/domain/push_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../helpers/fake_http.dart';

/// The whole app wired as in production, with only the phone and the network faked.
Map<String, Object?> _owner(String societyId, {String? name}) => {
  'roleCode': 2,
  'societyId': societyId,
  'societyName': ?name,
};

class _FakePush implements PushMessaging {
  const new(this._token, this.tokenRefreshes);

  final String _token;

  @override
  final Stream<String> tokenRefreshes;

  @override
  Future<String?> token() async => _token;
}

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '0.1.0');

  Future<FakeHttpAdapter> start(
    WidgetTester tester, {
    required Future<FakeReply> Function(String path) reply,
    AuthTokens? tokens,
    PushMessaging? push,
  }) async {
    // Every home has the bell, which reads the unread count.
    final adapter = FakeHttpAdapter(
      (options) =>
          options.path == 'notifications/unread-count' ? Future.value(okReply({'count': 2})) : reply(options.path),
    );
    // The app keeps the child a parent chose in the preferences; here they stay in memory.
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await configureDependencies(
      config,
      device: device,
      tokens: InMemoryTokenStorage(tokens),
      installMarker: InMemoryInstallMarker(started: true),
      httpAdapter: adapter,
    );
    if (push != null) {
      getIt
        ..unregister<PushMessaging>()
        ..registerSingleton<PushMessaging>(push);
    }
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    return adapter;
  }

  tearDown(getIt.reset);

  testWidgets('with no session, starts on sign-in', (tester) async {
    await start(tester, reply: (_) async => throw StateError('no call expected'));
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('with a stored session, restores it from /me and opens home', (tester) async {
    final adapter = await start(
      tester,
      tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'),
      reply: (path) async => path == 'society/access-blocks'
          ? okReply([])
          : okReply({
              'person': {'id': 'p1', 'email': 'asha.rao@example.com', 'firstName': 'Asha', 'preferredLanguage': 'en'},
              'contexts': [_owner('s1')],
            }),
    );
    // An Owner's home also asks what is blocked in the Society (SOC-02), and how many notices are unread (NTF-02).
    expect(adapter.paths, unorderedEquals(['/v1/me', '/v1/society/access-blocks', '/v1/notifications/unread-count']));
    expect(find.text('Welcome, Asha'), findsOneWidget);
  });

  testWidgets('a parent opens on their first child and can switch to a sibling, and logging out clears it', (
    tester,
  ) async {
    Map<String, Object?> child(String id, String name) => {
      'studentId': id,
      'firstName': name,
      'lastName': 'Shetty',
      'institutionName': 'Green Valley School',
      'className': '7th',
      'sectionName': 'A',
      'isBlocked': false,
    };
    await start(
      tester,
      tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'),
      reply: (path) async => path == 'auth/logout'
          ? okReply(null)
          : okReply({
              'person': {'id': 'p1', 'email': 'asha.rao@example.com', 'firstName': 'Asha', 'preferredLanguage': 'en'},
              'contexts': [
                {
                  'roleCode': 5,
                  'isBlocked': false,
                  'children': [child('s1', 'Diya'), child('s2', 'Arun')],
                },
              ],
            }),
    );
    expect(find.text('Diya Shetty'), findsOneWidget);

    await tester.tap(find.byKey(const Key('child.switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('child.option.s2')));
    await tester.pumpAndSettle();
    expect(find.text('Arun Shetty'), findsOneWidget);
    expect(find.text('Diya Shetty'), findsNothing);

    await tester.tap(find.byKey(const Key('home.logout')));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byKey(const Key('child.switcher')), findsNothing);
  });

  group('notifications', () {
    const tokens = AuthTokens(accessToken: 'a', refreshToken: 'r');
    Future<FakeReply> owner(String path) async => switch (path) {
      'society/access-blocks' => okReply([]),
      'notifications' => okReply([], meta: {'limit': 20, 'nextCursor': null, 'hasMore': false}),
      'me/push-device' => okReply(null),
      _ => okReply({
        'person': {'id': 'p1', 'email': 'asha.rao@example.com', 'firstName': 'Asha', 'preferredLanguage': 'kn'},
        'contexts': [_owner('s1')],
      }),
    };

    testWidgets('the bell shows the unread count, opens the inbox and reads the count again on the way back', (
      tester,
    ) async {
      final adapter = await start(tester, tokens: tokens, reply: owner);
      expect(find.bySemanticsLabel('Notifications, 2 unread'), findsOneWidget);

      await tester.tap(find.byKey(const Key('home.bell')));
      await tester.pumpAndSettle();
      // An Owner has all four tabs.
      expect(find.text('All teachers'), findsOneWidget);
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(adapter.requests.where((request) => request.uri.path == '/v1/notifications').single.uri.queryParameters, {
        'tab': '1',
      });

      await tester.tap(find.byType(BackButton).evaluate().isEmpty ? find.byTooltip('Back') : find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(adapter.paths.where((path) => path == '/v1/notifications/unread-count'), hasLength(2));
    });

    testWidgets('signing in registers the phone’s push token, and a new token is registered again', (tester) async {
      final refreshes = StreamController<String>();
      addTearDown(refreshes.close);
      final adapter = await start(tester, tokens: tokens, reply: owner, push: _FakePush('tok-1', refreshes.stream));
      Iterable<Object?> registered() => adapter.requests
          .where((request) => request.uri.path == '/v1/me/push-device')
          .map((request) => bodyOf(request)['fcmToken']);
      // The language is the person's, which the app took on at sign-in.
      expect(
        adapter.requests.firstWhere((request) => request.uri.path == '/v1/me/push-device').data,
        containsPair('language', 'kn'),
      );
      expect(registered(), ['tok-1']);

      refreshes.add('tok-2');
      await tester.pumpAndSettle();
      expect(registered(), ['tok-1', 'tok-1']);
    });

    testWidgets('a new token while signed out is not registered: there is no one to register it for', (tester) async {
      final refreshes = StreamController<String>();
      addTearDown(refreshes.close);
      final adapter = await start(
        tester,
        reply: (_) async => throw StateError('no call expected'),
        push: _FakePush('tok-1', refreshes.stream),
      );
      refreshes.add('tok-2');
      await tester.pumpAndSettle();
      expect(adapter.paths, isNot(contains('/v1/me/push-device')));
    });

    testWidgets('with no push token from the phone, nothing is registered', (tester) async {
      final adapter = await start(tester, tokens: tokens, reply: owner);
      expect(adapter.paths, isNot(contains('/v1/me/push-device')));
    });
  });

  testWidgets('a 426 shows the update screen', (tester) async {
    await start(
      tester,
      tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'),
      reply: (_) async => errorReply(426, 'APP_UPDATE_REQUIRED'),
    );
    expect(find.text('Update required'), findsOneWidget);
  });

  testWidgets('logging out returns to sign-in', (tester) async {
    await start(
      tester,
      tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'),
      reply: (path) async => path == 'auth/logout' || path == 'society/access-blocks'
          ? okReply(path == 'auth/logout' ? null : [])
          : okReply({
              'person': {'id': 'p1', 'email': 'asha.rao@example.com', 'firstName': 'Asha', 'preferredLanguage': 'en'},
              'contexts': [_owner('s1')],
            }),
    );
    await tester.tap(find.byKey(const Key('home.logout')));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });

  group('role chooser', () {
    const tokens = AuthTokens(accessToken: 'a', refreshToken: 'r');

    Map<String, Object?> me(List<Object?> contexts) => {
      'person': {'id': 'p1', 'email': 'asha.rao@example.com', 'firstName': 'Asha', 'preferredLanguage': 'en'},
      'contexts': contexts,
    };

    testWidgets('two roles: choose one, AUTH-06 is called, and home opens as that role', (tester) async {
      final adapter = await start(
        tester,
        tokens: tokens,
        reply: (path) async => switch (path) {
          'auth/context' => okReply({'accessToken': 'a2', 'activeContext': _owner('s2')}),
          'society/access-blocks' => okReply([]),
          _ => okReply(me([_owner('s1', name: 'North Trust'), _owner('s2', name: 'South Trust')])),
        },
      );
      expect(find.text('Choose a role'), findsOneWidget);
      expect(find.text('North Trust'), findsOneWidget);
      expect(find.text('Welcome, Asha'), findsNothing);

      await tester.tap(find.text('South Trust'));
      await tester.pumpAndSettle();

      final call = adapter.requests.singleWhere((request) => request.uri.path == '/v1/auth/context');
      expect(call.data, {'roleCode': 2, 'societyId': 's2'});
      expect(find.text('Welcome, Asha'), findsOneWidget);

      await tester.tap(find.byKey(const Key('home.profile')));
      await tester.pumpAndSettle();
      expect(find.text('Society Owner'), findsOneWidget);
      expect(find.text('South Trust'), findsOneWidget);
      expect(find.byKey(const Key('profile.switchRole')), findsOneWidget);
    });

    testWidgets('a role that is gone is explained, and the list stays', (tester) async {
      await start(
        tester,
        tokens: tokens,
        reply: (path) async => path == 'auth/context'
            ? errorReply(403, 'CONTEXT_NOT_AVAILABLE')
            : okReply(me([_owner('s1', name: 'North Trust'), _owner('s2', name: 'South Trust')])),
      );
      await tester.tap(find.text('North Trust'));
      await tester.pumpAndSettle();
      expect(find.text('You no longer have that role. Choose another one or sign in again.'), findsOneWidget);
      expect(find.text('South Trust'), findsOneWidget);
    });

    testWidgets('an account with no role says so and can log out', (tester) async {
      await start(
        tester,
        tokens: tokens,
        reply: (path) async => path == 'auth/logout' ? okReply(null) : okReply(me([])),
      );
      expect(find.text('No role available'), findsOneWidget);
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsOneWidget);
    });
  });
}
