import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/push/data/push_device_repository_impl.dart';
import 'package:bravynix_school_erp/features/push/domain/push_device_repository.dart';
import 'package:bravynix_school_erp/features/push/domain/push_messaging.dart';
import 'package:bravynix_school_erp/features/push/domain/push_registrar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_http.dart';

class _MockMessaging extends Mock implements PushMessaging;

class _MockDevices extends Mock implements PushDeviceRepository;

void main() {
  test('registers the token, the platform, the version and the language of this install (ME-04)', () async {
    final adapter = FakeHttpAdapter((_) async => okReply(null));
    final api = createApiClient(
      config: const AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1'),
      device: const AppDevice(platform: DevicePlatform.ios, appVersion: '1.4.2'),
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'kn',
      adapter: adapter,
    );
    await PushDeviceRepositoryImpl(
      api: api,
      device: const AppDevice(platform: DevicePlatform.ios, appVersion: '1.4.2'),
      language: () => 'kn',
    ).register('tok-1');
    expect(adapter.requests.single.method, 'PUT');
    expect(adapter.paths, ['/v1/me/push-device']);
    expect(bodyOf(adapter.requests.single), {
      'fcmToken': 'tok-1',
      'platform': 2,
      'appVersion': '1.4.2',
      'language': 'kn',
    });
  });

  group('PushRegistrar', () {
    late _MockMessaging messaging;
    late _MockDevices devices;
    setUp(() {
      messaging = _MockMessaging();
      devices = _MockDevices();
    });

    test('sends the phone’s token to the server', () async {
      when(messaging.token).thenAnswer((_) async => 'tok-1');
      when(() => devices.register('tok-1')).thenAnswer((_) async {});
      expect(await PushRegistrar(messaging, devices).register(), isTrue);
      verify(() => devices.register('tok-1')).called(1);
    });

    test('with no token from the phone, asks the server for nothing', () async {
      when(messaging.token).thenAnswer((_) async => null);
      expect(await PushRegistrar(messaging, devices).register(), isFalse);
      verifyNever(() => devices.register(any()));
    });

    test('an empty token is no token: the server is asked for nothing', () async {
      when(messaging.token).thenAnswer((_) async => '');
      expect(await PushRegistrar(messaging, devices).register(), isFalse);
      verifyNever(() => devices.register(any()));
    });

    test('a refusal is not shown: the next sign-in tries again', () async {
      when(messaging.token).thenAnswer((_) async => 'tok-1');
      when(() => devices.register(any())).thenThrow(const ApiFailure.network());
      expect(await PushRegistrar(messaging, devices).register(), isFalse);
    });
  });

  test('until the Firebase driver joins, the phone gives no token and no refresh', () async {
    const messaging = UnavailablePushMessaging();
    expect(await messaging.token(), isNull);
    expect(await messaging.tokenRefreshes.isEmpty, isTrue);
  });
}
