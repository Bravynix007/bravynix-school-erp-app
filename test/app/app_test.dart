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
        'contexts': <Object?>[],
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
              'contexts': <Object?>[],
            }),
    );
    await tester.tap(find.byKey(const Key('home.logout')));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });
}
