import 'package:bravynix_school_erp/app/app.dart';
import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/storage/install_marker.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_http.dart';

/// QA for A2 through the whole app, with ME-01 shaped as the real API sends it:
/// `session.activeContext` carries only `roleCode` and `societyId`.
Map<String, Object?> _owner(String societyId, String name) => {
  'roleCode': 2,
  'societyId': societyId,
  'societyName': name,
};

Map<String, Object?> _me({String? active}) => {
  'person': {'id': 'p1', 'email': 'asha.rao@example.com', 'firstName': 'Asha', 'preferredLanguage': 'en'},
  'session': {
    'id': 'sess-1',
    'activeContext': active == null ? null : {'roleCode': 2, 'societyId': active},
  },
  'contexts': [_owner('s1', 'North Trust'), _owner('s2', 'South Trust')],
};

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '0.1.0');
  const tokens = AuthTokens(accessToken: 'a', refreshToken: 'r');

  Future<FakeHttpAdapter> start(WidgetTester tester, {String? active, Duration switchDelay = Duration.zero}) async {
    final adapter = FakeHttpAdapter(
      (options) => options.path == 'auth/context'
          ? Future.delayed(switchDelay, () => okReply({'accessToken': 'a2', 'activeContext': options.data}))
          : Future.value(okReply(_me(active: active))),
    );
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

  testWidgets('after a restart with a role active, Profile names its Society', (tester) async {
    await start(tester, active: 's2');
    expect(find.text('Welcome, Asha'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home.profile')));
    await tester.pumpAndSettle();
    expect(find.text('Society Owner'), findsOneWidget);
    expect(find.text('South Trust'), findsOneWidget, reason: 'the restored active context lost the Society name');
  });

  testWidgets('Switch role, then Back: Profile again, same role, no call', (tester) async {
    final adapter = await start(tester, active: 's2');
    await tester.tap(find.byKey(const Key('home.profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile.switchRole')));
    await tester.pumpAndSettle();
    expect(find.text('Choose how to continue'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile.switchRole')), findsOneWidget);
    expect(adapter.paths.where((path) => path.endsWith('auth/context')), isEmpty);
  });

  testWidgets('choosing the role already in use from Switch role needs no call', (tester) async {
    final adapter = await start(tester, active: 's2');
    await tester.tap(find.byKey(const Key('home.profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile.switchRole')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('South Trust'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Asha'), findsOneWidget);
    expect(adapter.paths.where((path) => path.endsWith('auth/context')), isEmpty);
  });

  testWidgets('two quick taps on two roles send one switch', (tester) async {
    final adapter = await start(tester, switchDelay: const Duration(milliseconds: 300));
    await tester.tap(find.text('North Trust'));
    await tester.tap(find.text('South Trust'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(adapter.paths.where((path) => path.endsWith('auth/context')), hasLength(1));
    expect(find.text('Welcome, Asha'), findsOneWidget);
  });

  testWidgets('without an active role, /profile is not reachable', (tester) async {
    await start(tester);
    expect(find.text('Choose how to continue'), findsOneWidget);
    expect(find.byKey(const Key('home.profile')), findsNothing);
    expect(find.byTooltip('Back'), findsNothing);
  });
}
