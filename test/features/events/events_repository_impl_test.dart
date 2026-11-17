import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/events/data/events_repository_impl.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/events.dart';
import '../../helpers/fake_http.dart';

void main() {
  ({EventsRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: const AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1'),
      device: const AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2'),
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: EventsRepositoryImpl(api: api), adapter: adapter);
  }

  test('reads the events of a span of days, for a child when a parent asks', () async {
    final (:repository, :adapter) = build(() => okReply([eventJson(), eventJson(id: 'e2', isHoliday: true)]));
    final events = await repository.events(
      from: DateTime(2026, 11),
      to: DateTime(2026, 11, 30),
      holidaysOnly: true,
      studentId: 's1',
    );
    expect(adapter.requests.single.uri.queryParameters, {
      'from': '2026-11-01',
      'to': '2026-11-30',
      'holidays': 'true',
      'studentId': 's1',
    });
    expect(events.first.startDate, DateTime(2026, 11, 20));
    expect(events.first.endDate, DateTime(2026, 11, 22));
    expect(events.first.audience, EventAudience.studentsAndParents);
    expect(events.first.scope, EventScope.institution);
    expect(events.first.presetImageCode, 'cultural');
    expect(events.first.canEdit, isTrue);
    expect(events.last.holidayType, HolidayType.vacation);
    expect(events.last.holidayClassIds, ['c1', 'c2']);
  });

  test('asks for no holidays filter and no child unless named', () async {
    final (:repository, :adapter) = build(() => okReply(<Object?>[]));
    await repository.events(from: DateTime(2026, 11), to: DateTime(2026, 11, 30));
    expect(adapter.requests.single.uri.queryParameters.keys, ['from', 'to']);
  });

  test('reads one event, naming the child for a parent', () async {
    final (:repository, :adapter) = build(() => okReply(eventJson(id: 'a/b')));
    final event = await repository.event('a/b', studentId: 's1');
    expect(event.version, 3);
    expect(adapter.paths, ['/v1/events/a%2Fb']);
    expect(adapter.requests.single.uri.queryParameters, {'studentId': 's1'});
  });

  test('an answer with an audience the app does not know is an unexpected failure, not a wrong screen', () async {
    final (:repository, adapter: _) = build(() => okReply({...eventJson(), 'audience': 9}));
    await expectLater(repository.event('e1'), throwsA(isA<ApiFailure>()));
  });
}
