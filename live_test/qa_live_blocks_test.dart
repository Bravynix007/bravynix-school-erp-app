// QA attacks on the app's section-block screens (SOC-02, 423 SECTION_BLOCKED) against the real API on a fresh
// database with section blocks. Blocks and an Institution Admin grant are arranged by SQL, as Super Admin.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/install_marker.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/auth/data/auth_repository_impl.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/features/blocks/data/blocks_repository_impl.dart';
import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _api = String.fromEnvironment('LIVE_API');
const _db = String.fromEnvironment('LIVE_DB');
const _device = AppDevice(platform: DevicePlatform.android, appVersion: '0.1.0', label: 'qa blocks');
const _owner = 'so-a1@two-worlds.test';
const _admin = 'ia-a1@two-worlds.test';
const _societyA = '00000000-0000-7000-8000-000000001001';
const _sa1 = "(select id from users where email = 'sa1@two-worlds.test')";
const _reason = '<b>Dues</b> & "fees"';

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

/// Runs as Super Admin, so row security lets the statement see Societies, Institutions and blocks.
Future<String> _sql(String statement) async {
  final result = await Process.run('su', [
    'postgres',
    '-c',
    "psql -qtA -d $_db -c \"begin; select set_config('app.role_code','1',true); $statement; commit\"",
  ]);
  if (result.exitCode != 0) throw StateError('psql: ${result.stderr}');
  final lines = (result.stdout as String).split('\n').where((line) => line.startsWith('v=')).toList();
  return lines.isEmpty ? '' : lines.last.substring(2);
}

Future<void> _openGates() => _sql(
  "update otp_challenges set created_at = created_at - interval '20 minutes', "
  "expires_at = expires_at - interval '20 minutes'; delete from public_call_counters",
);

/// One signed-in person: their repository, the API client their calls go through, and the blocks repository.
class _Person {
  new(this.adapter) {
    final tokens = InMemoryTokenStorage();
    final events = ApiEvents();
    api = createApiClient(
      config: const AppConfig(flavor: Flavor.dev, apiBaseUrl: _api),
      device: _device,
      tokens: tokens,
      events: events,
      language: () => 'en',
      adapter: adapter,
    );
    auth = AuthRepositoryImpl(
      api: api,
      tokens: tokens,
      installMarker: InMemoryInstallMarker(started: true),
      device: _device,
      events: events,
    );
    blocks = BlocksRepositoryImpl(api: api);
  }

  final _EchoAdapter adapter;
  late final ApiClient api;
  late final AuthRepositoryImpl auth;
  late final BlocksRepositoryImpl blocks;

  Future<void> signIn(String email) async {
    await _openGates();
    await auth.requestOtp(email);
    await auth.verifyOtp(email: email, code: adapter.devOtp!);
  }

  /// A call no block allows: the Institutions of the active Society.
  Future<ApiFailure?> institutions() async {
    try {
      await api.data<Object?>('institutions', parse: (data) => data);
      return null;
    } on ApiFailure catch (failure) {
      return failure;
    }
  }
}

void main() {
  if (_api.isEmpty || _db.isEmpty) {
    test(
      'QA live block checks',
      () {},
      skip: 'Set --dart-define=LIVE_API=http://localhost:3000/v1 and --dart-define=LIVE_DB=<database>',
    );
    return;
  }

  final l10n = lookupAppLocalizations(const Locale('en'));
  late String institutionId;
  late String institutionName;

  setUpAll(() async {
    final found = await _sql(
      "select 'v=' || id || '|' || name from institutions where society_id = '$_societyA' and status = 1 order by name limit 1",
    );
    [institutionId, institutionName] = found.split('|');
    await _sql(
      'update access_blocks set lifted_at = now(), lifted_by = $_sa1 where lifted_at is null; '
      'insert into access_blocks (society_id, institution_id, section, reason, created_by) '
      "values ('$_societyA', '$institutionId', 2, '${_reason.replaceAll('"', r'\"')}', $_sa1)",
    );
  });

  final owner = _Person(_EchoAdapter());

  test('L1 a staff block: the Owner is not blocked, works, and reads the block with its reason as sent', () async {
    await owner.signIn(_owner);
    final session = (await owner.auth.restoreSession())!;
    stdout.writeln('L1 active: ${session.activeContext?.societyName} isBlocked=${session.activeContext?.isBlocked}');
    expect(session.activeContext?.isBlocked, isFalse);
    expect(await owner.institutions(), isNull);
    final blocks = await owner.blocks.societyBlocks();
    stdout.writeln('L1 SOC-02: ${blocks.map((b) => '${b.section.name}/${b.institutionName}/${b.reason}').join(', ')}');
    expect(blocks, hasLength(1));
    expect(blocks.single.section, BlockSection.staff);
    expect(blocks.single.institutionName, institutionName);
    expect(blocks.single.reason, _reason);
    expect(blocks.single.blockedAt.isUtc || blocks.single.blockedAt.timeZoneOffset == Duration.zero, isTrue);
  });

  test(
    'L2 an Owners block too: the context says blocked after ME-01, calls are 423 owners, SOC-02 still answers both',
    () async {
      await _sql(
        "insert into access_blocks (society_id, section, reason, created_by) values ('$_societyA', 1, 'Unpaid', $_sa1)",
      );
      final failure = await owner.institutions();
      stdout.writeln('L2 call: ${failure?.statusCode} ${failure?.code} ${failure?.details}');
      expect(failure?.statusCode, 423);
      expect(failure?.code, 'SECTION_BLOCKED');
      expect(failure?.details['section'], 'owners');
      expect(roleErrorText(l10n, failure!), l10n.errorSectionBlockedOwners);
      final session = (await owner.auth.restoreSession())!;
      expect(session.activeContext?.isBlocked, isTrue);
      final blocks = await owner.blocks.societyBlocks();
      expect(blocks.map((b) => b.section), [BlockSection.staff, BlockSection.owners]);
    },
  );

  test('L3 the Owners block lifted: the next call works and ME-01 is not blocked', () async {
    await _sql('update access_blocks set lifted_at = now(), lifted_by = $_sa1 where lifted_at is null and section = 1');
    expect(await owner.institutions(), isNull);
    expect((await owner.auth.restoreSession())!.activeContext?.isBlocked, isFalse);
  });

  test(
    'L4 an Institution Admin of the blocked Institution only: blocked at sign-in, 423 staff, and the group copy',
    () async {
      await _sql(
        'insert into role_assignments (user_id, role_code, society_id, institution_id, staff_member_id) '
        "select id, 3, '$_societyA', '$institutionId', gen_random_uuid() from users where email = '$_admin'",
      );
      final admin = _Person(_EchoAdapter());
      await admin.signIn(_admin);
      final session = (await admin.auth.restoreSession())!;
      stdout.writeln('L4 IA active: ${session.activeContext?.role} isBlocked=${session.activeContext?.isBlocked}');
      expect(session.activeContext?.isBlocked, isTrue);
      final failure = await admin.institutions();
      expect(failure?.statusCode, 423);
      expect(failure?.details['section'], 'staff');
      expect(roleErrorText(l10n, failure!), l10n.errorSectionBlocked);
      // An Admin may not read the Society's blocks.
      try {
        await admin.blocks.societyBlocks();
        fail('SOC-02 answered an Institution Admin');
      } on ApiFailure catch (refused) {
        stdout.writeln('L4 SOC-02 as IA: ${refused.statusCode} ${refused.code}');
        expect(refused.statusCode, 403);
      }
    },
  );
}
