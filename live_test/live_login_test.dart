// Sign-in against the real API, not a fake: AUTH-01, AUTH-02, AUTH-06, ME-01, AUTH-03
// and AUTH-04 through the app's own client, repository and models. It is not
// part of `flutter test`; see "Live checks" in the README.
import 'dart:convert';
import 'dart:typed_data';

import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/network/interceptors/auth_interceptor.dart';
import 'package:bravynix_school_erp/core/network/interceptors/headers_interceptor.dart';
import 'package:bravynix_school_erp/core/storage/install_marker.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/auth/data/auth_repository_impl.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/login_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations_en.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';

const _api = String.fromEnvironment('LIVE_API');
const _email = String.fromEnvironment('LIVE_EMAIL', defaultValue: 'so-a1@two-worlds.test');
const _other = String.fromEnvironment('LIVE_OTHER_EMAIL', defaultValue: 'so-a2@two-worlds.test');
const _locked = String.fromEnvironment('LIVE_LOCK_EMAIL', defaultValue: 'so-a3@two-worlds.test');
const _device = AppDevice(platform: DevicePlatform.android, appVersion: '0.1.0', label: 'live check');

/// Passes every call to the real network and keeps the OTP answer, whose
/// `devOtp` (a backend started with OTP_DEV_ECHO=true) stands in for the inbox.
class _EchoAdapter implements HttpClientAdapter {
  final HttpClientAdapter _inner = IOHttpClientAdapter();
  String? devOtp;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body, Future<void>? cancel) async {
    final response = await _inner.fetch(options, body, cancel);
    if (!options.path.endsWith('auth/otp')) return response;
    final bytes = (await response.stream.fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (all, chunk) => all..add(chunk),
    )).takeBytes();
    final json = jsonDecode(utf8.decode(bytes));
    if (json case {'data': {'devOtp': final String code}}) devOtp = code;
    return ResponseBody.fromBytes(bytes, response.statusCode, headers: response.headers);
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

void main() {
  if (_api.isEmpty) {
    test('live checks', () {}, skip: 'Set --dart-define=LIVE_API=http://localhost:3000/v1');
    return;
  }

  final adapter = _EchoAdapter();
  final tokens = InMemoryTokenStorage();
  final events = ApiEvents();
  final client = createApiClient(
    config: const AppConfig(flavor: Flavor.dev, apiBaseUrl: _api),
    device: _device,
    tokens: tokens,
    events: events,
    language: () => 'en',
    adapter: adapter,
  );
  final repository = AuthRepositoryImpl(
    api: client,
    tokens: tokens,
    installMarker: InMemoryInstallMarker(started: true),
    device: _device,
    events: events,
  );
  late AuthSession session;

  // A client without the auth interceptor, as the app's own refresh uses.
  final bare = Dio(BaseOptions(baseUrl: '$_api/'))
    ..httpClientAdapter = adapter
    ..interceptors.add(HeadersInterceptor(device: _device, language: () => 'en'));
  final refresher = DioTokenRefresher(bare);

  tearDownAll(events.dispose);

  test('AUTH-01 sends a code and says how long to wait', () async {
    final sent = await repository.requestOtp(_email);
    expect(sent.resendAfter, const Duration(seconds: 60));
    expect(adapter.devOtp, isNotNull, reason: 'start the API with OTP_DEV_ECHO=true');
  });

  test('a wrong code is refused with the attempts left', () async {
    await expectLater(
      repository.verifyOtp(email: _email, code: adapter.devOtp == '000000' ? '111111' : '000000'),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.code, 'code', 'OTP_INVALID')
            .having((f) => f.details['attemptsLeft'], 'attemptsLeft', 4),
      ),
    );
    expect(await tokens.read(), isNull);
  });

  test('AUTH-02 signs in, with the device, and keeps the tokens', () async {
    session = await repository.verifyOtp(email: _email, code: adapter.devOtp!);
    expect(session.person.email, _email);
    expect(session.contexts.map((c) => c.role), contains(RoleCode.societyOwner));
    expect(session.contexts.every((c) => c.societyId != null || c.role == RoleCode.studentParent), isTrue);
    expect(session.person.displayName, isNotEmpty);
    expect(await tokens.read(), isNotNull);
  });

  test('ME-01 restores the same person and contexts', () async {
    final restored = await repository.restoreSession();
    expect(restored?.person.id, session.person.id);
    expect(restored?.contexts, session.contexts);
  });

  test('AUTH-06 switches to a held role with a new access token, and refuses one that is not held', () async {
    final before = (await tokens.read())!;
    await repository.switchContext(session.contexts.first);
    final after = (await tokens.read())!;
    expect(after.accessToken, isNotEmpty);
    expect(after.refreshToken, before.refreshToken);
    // The new token works: ME-01 answers for the same person.
    expect((await repository.restoreSession())?.person.id, session.person.id);

    await expectLater(
      repository.switchContext(const AuthContext(role: RoleCode.studentParent)),
      throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'CONTEXT_NOT_AVAILABLE')),
    );
    expect((await tokens.read())?.accessToken, after.accessToken);
  });

  test('AUTH-04 signs out here and on the server', () async {
    final refreshToken = (await tokens.read())!.refreshToken;
    await repository.logout();
    expect(await tokens.read(), isNull);
    expect(await repository.restoreSession(), isNull);
    expect(await refresher.refresh(refreshToken), isA<RefreshRefused>());
  });

  test('AUTH-03 rotates the refresh token, and the spent one ends the session', () async {
    // A second person, as the first email has just used its resend gap.
    await repository.requestOtp(_other);
    await repository.verifyOtp(email: _other, code: adapter.devOtp!);
    final spent = (await tokens.read())!.refreshToken;

    final first = await refresher.refresh(spent);
    expect(first, isA<Refreshed>());
    final rotated = (first as Refreshed).tokens;
    expect(rotated.refreshToken, isNot(spent));

    final reused = await refresher.refresh(spent);
    expect(reused, isA<RefreshRefused>().having((r) => r.failure.code, 'code', 'REFRESH_TOKEN_REUSED'));
    // The reuse ends the whole session, so the rotated token is dead too.
    expect(await refresher.refresh(rotated.refreshToken), isA<RefreshRefused>());
  });

  test('five wrong codes lock the email, and the app words the wait', () async {
    // Leaves this email locked for 30 minutes: run it on a freshly seeded database.
    await repository.requestOtp(_locked);
    ApiFailure? last;
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await repository.verifyOtp(email: _locked, code: adapter.devOtp == '000000' ? '111111' : '000000');
      } on ApiFailure catch (failure) {
        last = failure;
      }
    }
    expect(last?.code, 'OTP_ATTEMPTS_EXCEEDED');
    expect(last?.isLockedOut, isTrue);
    expect(loginErrorText(AppLocalizationsEn(), last!), 'Too many incorrect codes. Try again in 30 minutes.');

    await expectLater(
      repository.requestOtp(_locked),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.isLockedOut, 'locked', isTrue)
            .having(
              (f) => loginErrorText(AppLocalizationsEn(), f),
              'copy',
              startsWith('Too many failed sign-ins. Try again in '),
            ),
      ),
    );
  });
}
