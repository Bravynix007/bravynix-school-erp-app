import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  late ApiEvents events;
  late InMemoryTokenStorage tokens;

  setUp(() {
    events = ApiEvents();
    tokens = InMemoryTokenStorage();
  });

  ApiClient clientWith(FakeHttpAdapter adapter) => createApiClient(
    config: config,
    device: device,
    tokens: tokens,
    events: events,
    language: () => 'kn',
    adapter: adapter,
  );

  Map<String, dynamic> asMap(Object? data) => data! as Map<String, dynamic>;

  group('ApiClient', () {
    test('unwraps data and sends the mobile headers', () async {
      await tokens.write(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
      final adapter = FakeHttpAdapter((_) async => okReply({'name': 'Diya'}));

      final data = await clientWith(adapter).data('me', parse: asMap);

      expect(data, {'name': 'Diya'});
      final request = adapter.requests.single;
      expect(request.uri.toString(), 'http://api.test/v1/me');
      expect(request.headers['Authorization'], 'Bearer a1');
      expect(request.headers['X-App-Version'], '1.4.2');
      expect(request.headers['X-App-Platform'], 'android');
      expect(request.headers['Accept-Language'], 'kn');
      expect(request.headers['X-Request-Id'], matches(RegExp(r'^[0-9a-f-]{36}$')));
    });

    test('anonymous calls go without the token', () async {
      await tokens.write(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
      final adapter = FakeHttpAdapter((_) async => okReply(null, status: 202));
      await clientWith(adapter).data<void>('auth/otp', method: HttpMethod.post, anonymous: true, parse: (_) {});
      expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('maps the error envelope: code, data, field errors, Retry-After', () async {
      final replies = [
        errorReply(
          401,
          'OTP_INVALID',
          extra: {
            'data': {'attemptsLeft': 3},
          },
        ),
        errorReply(429, 'OTP_RESEND_TOO_SOON', headers: {'retry-after': '42'}),
        errorReply(
          400,
          'VALIDATION_FAILED',
          extra: {
            'errors': [
              {'field': 'email', 'code': 'INVALID_EMAIL', 'message': 'Enter a valid email'},
            ],
          },
        ),
      ];
      final client = clientWith(FakeHttpAdapter((_) async => replies.removeAt(0)));

      Future<ApiFailure> failureOf() async {
        try {
          await client.data<void>('auth/otp/verify', method: HttpMethod.post, anonymous: true, parse: (_) {});
        } on ApiFailure catch (failure) {
          return failure;
        }
        throw StateError('expected a failure');
      }

      final invalid = await failureOf();
      expect(invalid.code, 'OTP_INVALID');
      expect(invalid.details['attemptsLeft'], 3);
      expect(invalid.requestId, 'req-2');

      final tooSoon = await failureOf();
      expect(tooSoon.retryAfter, const Duration(seconds: 42));
      expect(tooSoon.isRetryable, isTrue);

      final validation = await failureOf();
      expect(validation.fieldError('email')?.message, 'Enter a valid email');
    });

    test('refreshes once on TOKEN_EXPIRED and repeats the call', () async {
      await tokens.write(const AuthTokens(accessToken: 'old', refreshToken: 'r1'));
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == 'auth/refresh') {
          expect(bodyOf(options), {'refreshToken': 'r1'});
          return okReply({'accessToken': 'new', 'refreshToken': 'r2'});
        }
        return options.headers['Authorization'] == 'Bearer new' ? okReply({'id': 1}) : errorReply(401, 'TOKEN_EXPIRED');
      });

      expect(await clientWith(adapter).data('me', parse: asMap), {'id': 1});
      expect(adapter.paths, ['/v1/me', '/v1/auth/refresh', '/v1/me']);
      expect(await tokens.read(), const AuthTokens(accessToken: 'new', refreshToken: 'r2'));
    });

    test('concurrent expired calls share one refresh (a refresh token is single use)', () async {
      await tokens.write(const AuthTokens(accessToken: 'old', refreshToken: 'r1'));
      var refreshes = 0;
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == 'auth/refresh') {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return okReply({'accessToken': 'new', 'refreshToken': 'r2'});
        }
        return options.headers['Authorization'] == 'Bearer new'
            ? okReply({'path': options.path})
            : errorReply(401, 'TOKEN_EXPIRED');
      });
      final client = clientWith(adapter);

      final results = await Future.wait([
        client.data('students', parse: asMap),
        client.data('home', parse: asMap),
        client.data('notifications', parse: asMap),
      ]);

      expect(refreshes, 1);
      expect(results.map((r) => r['path']), ['students', 'home', 'notifications']);
    });

    test('a failed refresh clears the tokens and ends the session', () async {
      await tokens.write(const AuthTokens(accessToken: 'old', refreshToken: 'r1'));
      final ended = <ApiFailure>[];
      events.sessionEnded.listen(ended.add);
      final adapter = FakeHttpAdapter(
        (options) async =>
            options.path == 'auth/refresh' ? errorReply(401, 'REFRESH_TOKEN_REUSED') : errorReply(401, 'TOKEN_EXPIRED'),
      );

      await expectLater(clientWith(adapter).data('me', parse: asMap), throwsA(isA<ApiFailure>()));
      await pumpEventQueue();

      expect(await tokens.read(), isNull);
      // The server's own failure, not a generic "expired" (review A4).
      expect(ended.single.code, 'REFRESH_TOKEN_REUSED');
    });

    test('SESSION_ENDED signs out locally with the reason', () async {
      await tokens.write(const AuthTokens(accessToken: 'a', refreshToken: 'r'));
      final ended = <ApiFailure>[];
      events.sessionEnded.listen(ended.add);
      final adapter = FakeHttpAdapter(
        (_) async => errorReply(
          401,
          'SESSION_ENDED',
          extra: {
            'data': {'reason': 'blocked'},
          },
        ),
      );

      await expectLater(clientWith(adapter).data('me', parse: asMap), throwsA(isA<ApiFailure>()));
      await pumpEventQueue();

      expect(await tokens.read(), isNull);
      expect(ended.single.details['reason'], 'blocked');
    });

    test('426 raises update required', () async {
      final updates = <ApiFailure>[];
      events.updateRequired.listen(updates.add);
      final adapter = FakeHttpAdapter(
        (_) async => errorReply(
          426,
          'APP_UPDATE_REQUIRED',
          extra: {
            'data': {'storeUrl': 'https://play.google.com/store'},
          },
        ),
      );

      await expectLater(clientWith(adapter).data('me', parse: asMap), throwsA(isA<ApiFailure>()));
      await pumpEventQueue();

      expect(updates.single.details['storeUrl'], 'https://play.google.com/store');
    });

    test('an answer that is not the envelope is unexpected', () async {
      final adapter = FakeHttpAdapter(
        (_) async => (status: 502, body: {'html': true}, headers: const <String, String>{}),
      );
      await expectLater(
        clientWith(adapter).data('me', parse: asMap),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.code, 'code', 'INTERNAL_ERROR')
              .having((f) => f.isRetryable, 'retryable', isTrue),
        ),
      );
    });

    test('a half-formed error body is still an ApiFailure (re-review R-A4)', () async {
      final adapter = FakeHttpAdapter(
        (options) async => switch (options.path) {
          'gateway' => (
            status: 502,
            body: {'success': false, 'statusCode': 502, 'code': null},
            headers: const <String, String>{},
          ),
          _ => (
            status: 400,
            body: {
              'success': false,
              'statusCode': 400,
              'code': 'VALIDATION_FAILED',
              'message': 5,
              'errors': 'not a list',
              'requestId': 7,
              'data': ['not', 'a', 'map'],
            },
            headers: const <String, String>{},
          ),
        },
      );
      final client = clientWith(adapter);

      await expectLater(
        client.data<Object?>('gateway', parse: (d) => d),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'INTERNAL_ERROR')),
      );
      await expectLater(
        client.data<Object?>('odd', parse: (d) => d),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.code, 'code', 'VALIDATION_FAILED')
              .having((f) => f.message, 'message', '')
              .having((f) => f.fieldErrors, 'fieldErrors', isEmpty)
              .having((f) => f.details, 'details', isEmpty),
        ),
      );
    });

    test('a malformed field error entry is read without throwing', () {
      expect(FieldError.fromJson(const {'field': 3, 'code': null}), const FieldError(field: '', code: '', message: ''));
    });

    test('repeats array query values and drops nulls', () async {
      final adapter = FakeHttpAdapter((_) async => okReply(<Object?>[]));
      await clientWith(adapter).data<Object?>(
        'students',
        query: {
          'status': [1, 2],
          'q': 'diya',
          'cursor': null,
        },
        parse: (d) => d,
      );
      final uri = adapter.requests.single.uri;
      expect(uri.queryParametersAll['status'], ['1', '2']);
      expect(uri.queryParameters.containsKey('cursor'), isFalse);
    });
  });
}
