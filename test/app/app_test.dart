import 'package:bravynix_school_erp/app/app.dart';
import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/storage/install_marker.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_http.dart';

/// The whole app wired as in production, with only the phone and the network faked.
Map<String, Object?> _owner(String societyId, {String? name}) => {
  'roleCode': 2,
  'societyId': societyId,
  'societyName': ?name,
};

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '0.1.0');

  Future<FakeHttpAdapter> start(
    WidgetTester tester, {
    required Future<FakeReply> Function(String path) reply,
    AuthTokens? tokens,
  }) async {
    final adapter = FakeHttpAdapter((options) => reply(options.path));
    await configureDependencies(
      config,
      device: device,
      tokens: InMemoryTokenStorage(tokens),
      installMarker: InMemoryInstallMarker(started: true),
      httpAdapter: adapter,
    );
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
      reply: (_) async => okReply({
        'person': {'id': 'p1', 'email': 'asha.rao@example.com', 'firstName': 'Asha', 'preferredLanguage': 'en'},
        'contexts': [_owner('s1')],
      }),
    );
    expect(adapter.paths, ['/v1/me']);
    expect(find.text('Welcome, Asha'), findsOneWidget);
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
      reply: (path) async => path == 'auth/logout'
          ? okReply(null)
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
        reply: (path) async => path == 'auth/context'
            ? okReply({'accessToken': 'a2', 'activeContext': _owner('s2')})
            : okReply(me([_owner('s1', name: 'North Trust'), _owner('s2', name: 'South Trust')])),
      );
      expect(find.text('Choose how to continue'), findsOneWidget);
      expect(find.text('North Trust'), findsOneWidget);
      expect(find.text('Welcome, Asha'), findsNothing);

      await tester.tap(find.text('South Trust'));
      await tester.pumpAndSettle();

      final call = adapter.requests.last;
      expect(call.uri.path, '/v1/auth/context');
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
