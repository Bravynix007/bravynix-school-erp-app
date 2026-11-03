import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/masters/data/master_models.dart';
import 'package:bravynix_school_erp/features/masters/data/masters_repository_impl.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  var now = DateTime.utc(2026, 11, 3, 6);
  setUp(() => now = DateTime.utc(2026, 11, 3, 6));

  ({MastersRepositoryImpl repository, FakeHttpAdapter adapter}) build(Future<FakeReply> Function(int call) reply) {
    var calls = 0;
    final adapter = FakeHttpAdapter((_) => reply(calls++));
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: MastersRepositoryImpl(api: api, clock: () => now), adapter: adapter);
  }

  FakeReply listing(List<Object?> data, {String etag = 'W/"one"'}) => (
    status: 200,
    body: okReply(data).body,
    headers: {'etag': etag},
  );

  const notModified = (status: 304, body: null, headers: <String, String>{});

  final categories = [
    {'id': 'c1', 'code': 'LOWER_PRIMARY', 'name': 'Lower Primary', 'displayOrder': 1, 'status': 1, 'version': 1},
  ];

  test('reads a master and keeps it, so the same list is not asked for again within five minutes', () async {
    final (:repository, :adapter) = build((_) async => listing(categories));
    final first = await repository.entries(MasterType.classCategories);
    expect(first.single, const MasterEntry(id: 'c1', name: 'Lower Primary', code: 'LOWER_PRIMARY'));
    now = now.add(const Duration(minutes: 4, seconds: 59));
    expect(await repository.entries(MasterType.classCategories), first);
    expect(adapter.paths, ['/v1/masters/class-categories']);
    expect(adapter.requests.single.headers.containsKey('If-None-Match'), isFalse);
  });

  test('after five minutes it asks with the tag it holds, and a 304 keeps the list and the clock', () async {
    final (:repository, :adapter) = build((call) async => call == 0 ? listing(categories) : notModified);
    final first = await repository.entries(MasterType.classCategories);
    now = now.add(const Duration(minutes: 5));
    expect(await repository.entries(MasterType.classCategories), first);
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.headers['If-None-Match'], 'W/"one"');
    // The 304 counts as a read: the next five minutes cost nothing.
    now = now.add(const Duration(minutes: 4));
    await repository.entries(MasterType.classCategories);
    expect(adapter.requests, hasLength(2));
  });

  test('a changed list replaces the one held, with its new tag', () async {
    final (:repository, :adapter) = build(
      (call) async => switch (call) {
        0 => listing(categories),
        1 => listing([
          ...categories,
          {'id': 'c2', 'code': 'HIGH_SCHOOL', 'name': 'High School'},
        ], etag: 'W/"two"'),
        _ => notModified,
      },
    );
    await repository.entries(MasterType.classCategories);
    now = now.add(const Duration(minutes: 6));
    expect(await repository.entries(MasterType.classCategories), hasLength(2));
    now = now.add(const Duration(minutes: 6));
    expect(await repository.entries(MasterType.classCategories), hasLength(2));
    expect(adapter.requests.last.headers['If-None-Match'], 'W/"two"');
  });

  test('sends the parent of a state, a city or a predefined class, and keeps each list apart', () async {
    final (:repository, :adapter) = build(
      (call) async => listing([
        {'id': 'x$call', 'name': 'Entry $call', 'stateId': 's1'},
      ]),
    );
    final a = await repository.entries(MasterType.cities, parentId: 's1');
    final b = await repository.entries(MasterType.cities, parentId: 's2');
    expect(a.single.parentId, 's1');
    expect(a, isNot(b));
    expect(adapter.requests[0].uri.queryParameters, {'stateId': 's1'});
    expect(adapter.requests[1].uri.queryParameters, {'stateId': 's2'});
    await repository.entries(MasterType.states, parentId: 'k1');
    expect(adapter.requests[2].uri.queryParameters, {'countryId': 'k1'});
    await repository.entries(MasterType.predefinedClasses, parentId: 'c1');
    expect(adapter.requests[3].uri.queryParameters, {'classCategoryId': 'c1'});
  });

  test('sends no filter for a master that has none, even when given a parent', () async {
    final (:repository, :adapter) = build((_) async => listing([]));
    await repository.entries(MasterType.designations, parentId: 'ignored');
    expect(adapter.requests.single.uri.queryParameters, isEmpty);
  });

  test('turns a failure into an ApiFailure and holds nothing', () async {
    final (:repository, :adapter) = build((call) async => call == 0 ? errorReply(500, 'INTERNAL_ERROR') : listing([]));
    await expectLater(repository.entries(MasterType.designations), throwsA(isA<ApiFailure>()));
    expect(await repository.entries(MasterType.designations), isEmpty);
    expect(adapter.requests, hasLength(2));
  });

  group('MasterModels', () {
    test('reads the parent of each master, the code and the number', () {
      expect(MasterModels.entry({'id': 'a', 'name': 'Karnataka', 'countryId': 'k1', 'iso2': 'KA'}).parentId, 'k1');
      expect(MasterModels.entry({'id': 'a', 'name': 'Bengaluru', 'stateId': 's1'}).parentId, 's1');
      final klass = MasterModels.entry({
        'id': 'a',
        'code': 'CLASS_5',
        'name': '5th',
        'classCategoryId': 'c1',
        'numericValue': 5,
      });
      expect((klass.parentId, klass.numericValue, klass.code), ('c1', 5, 'CLASS_5'));
    });

    test('refuses an answer that is not a list of objects', () {
      expect(() => MasterModels.entries('nope'), throwsFormatException);
      expect(() => MasterModels.entries(['nope']), throwsFormatException);
    });
  });
}
