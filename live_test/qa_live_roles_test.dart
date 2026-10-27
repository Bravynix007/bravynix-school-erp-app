// QA attacks on A2 (AUTH-06, ME-01 after a switch) against the real API on a
// fresh database. Gives so-a2 a second Owner seat (in Society B) by SQL, as
// the seed has only single-role people. Run like the live checks.
import 'dart:convert';
import 'dart:io';
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
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';

const _api = String.fromEnvironment('LIVE_API');
// The database the backend runs on, for the checks that change seats by SQL.
// Empty skips this file; PGHOST and the other psql variables are honoured.
const _db = String.fromEnvironment('LIVE_DB');
const _device = AppDevice(platform: DevicePlatform.android, appVersion: '0.1.0', label: 'qa roles');
const _owner = 'so-a2@two-worlds.test';
const _ownerId = '00000000-0000-7000-8000-000000003005';
const _societyA = '00000000-0000-7000-8000-000000001001';
const _societyB = '00000000-0000-7000-8000-000000001002';

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
    devOtp = null;
    final json = jsonDecode(utf8.decode(bytes));
    if (json case {'data': {'devOtp': final String code}}) devOtp = code;
    return ResponseBody.fromBytes(bytes, response.statusCode, headers: response.headers);
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

Future<void> _sql(String statement) async {
  final result = await Process.run('su', ['postgres', '-c', 'psql -q -d $_db -c "$statement"']);
  if (result.exitCode != 0) throw StateError('psql: ${result.stderr}');
}

Future<void> _openGates() => _sql(
  "update otp_challenges set created_at = created_at - interval '20 minutes', "
  "expires_at = expires_at - interval '20 minutes'; delete from public_call_counters",
);

void main() {
  if (_api.isEmpty || _db.isEmpty) {
    test(
      'QA live role checks',
      () {},
      skip: 'Set --dart-define=LIVE_API=http://localhost:3000/v1 and --dart-define=LIVE_DB=<database>',
    );
    return;
  }

  final adapter = _EchoAdapter();
  final tokens = InMemoryTokenStorage();
  final events = ApiEvents();
  final ended = <ApiFailure>[];
  events.sessionEnded.listen(ended.add);
  final repository = AuthRepositoryImpl(
    api: createApiClient(
      config: const AppConfig(flavor: Flavor.dev, apiBaseUrl: _api),
      device: _device,
      tokens: tokens,
      events: events,
      language: () => 'en',
      adapter: adapter,
    ),
    tokens: tokens,
    installMarker: InMemoryInstallMarker(started: true),
    device: _device,
    events: events,
  );
  final bare = Dio(BaseOptions(baseUrl: '$_api/'))
    ..httpClientAdapter = adapter
    ..interceptors.add(HeadersInterceptor(device: _device, language: () => 'en'));
  final refresher = DioTokenRefresher(bare);
  late AuthSession signedIn;

  setUpAll(() async {
    await _sql(
      "begin; select set_config('app.role_code','1',true); "
      "insert into role_assignments (user_id, role_code, society_id, seat_no) values ('$_ownerId', 2, '$_societyB', 3); commit",
    );
  });
  tearDownAll(events.dispose);

  AuthContext ofSociety(AuthSession session, String id) => session.contexts.firstWhere((c) => c.societyId == id);

  test('R1 two Owner seats: two choices and no active role until one is chosen', () async {
    await _openGates();
    await repository.requestOtp(_owner);
    signedIn = await repository.verifyOtp(email: _owner, code: adapter.devOtp!);
    stdout.writeln('R1 contexts: ${signedIn.contexts.map((c) => '${c.role.code}/${c.societyName}').join(', ')}');
    expect(signedIn.contexts, hasLength(2));
    expect(signedIn.activeContext, isNull);
  });

  test('R2 the chosen role survives ME-01 and a refresh, as the same context the list shows', () async {
    final b = ofSociety(signedIn, _societyB);
    final before = (await tokens.read())!;
    await repository.switchContext(b);
    expect((await tokens.read())!.refreshToken, before.refreshToken);

    final restored = (await repository.restoreSession())!;
    stdout.writeln(
      'R2 ME-01 active: ${restored.activeContext?.role.code} ${restored.activeContext?.societyId} '
      'name=${restored.activeContext?.societyName}',
    );
    expect(restored.activeContext?.societyId, _societyB);
    // Profile shows the active context's Society, and the chooser compares it with the list.
    expect(
      restored.activeContext,
      ofSociety(restored, _societyB),
      reason: 'restored active context is not the listed one',
    );

    final refreshed = await refresher.refresh((await tokens.read())!.refreshToken);
    expect(refreshed, isA<Refreshed>());
    await tokens.write((refreshed as Refreshed).tokens);
    final again = (await repository.restoreSession())!;
    expect(again.activeContext?.societyId, _societyB);
  });

  test('R3 roles the person does not hold are refused and the tokens stay', () async {
    final kept = (await tokens.read())!;
    for (final context in [
      const AuthContext(role: RoleCode.societyOwner, societyId: '00000000-0000-7000-8000-00000000ffff'),
      const AuthContext(role: RoleCode.institutionAdmin, societyId: _societyA),
      const AuthContext(role: RoleCode.superAdmin),
      const AuthContext(role: RoleCode.societyOwner),
    ]) {
      try {
        await repository.switchContext(context);
        fail('switched to ${context.role} ${context.societyId}');
      } on ApiFailure catch (failure) {
        stdout.writeln('R3 ${context.role.code}/${context.societyId}: ${failure.statusCode} ${failure.code}');
        expect(failure.statusCode, anyOf(400, 403, 409, 422));
      }
      expect(await tokens.read(), kept);
    }
    expect((await repository.restoreSession())?.activeContext?.societyId, _societyB);
  });

  test('R4 the active seat is taken away: the next call ends the session with its reason', () async {
    await _sql(
      "begin; select set_config('app.role_code','1',true); "
      "update role_assignments set revoked_at = now() where user_id = '$_ownerId' and society_id = '$_societyB'; commit",
    );
    ended.clear();
    final restored = await repository.restoreSession();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    stdout.writeln(
      'R4 after revoke: restored=${restored != null} ended=${ended.map((f) => '${f.code}/${f.details['reason']}').join(',')}',
    );
    expect(restored, isNull);
    expect(ended.single.details['reason'], 'admin_revoked');
    expect(await tokens.read(), isNull);
  });

  test('R5 signing in again offers only the seat left, already active', () async {
    await _openGates();
    await repository.requestOtp(_owner);
    final session = await repository.verifyOtp(email: _owner, code: adapter.devOtp!);
    expect(session.contexts, hasLength(1));
    expect(session.activeContext, session.contexts.single);
    await repository.logout();
  });
}
