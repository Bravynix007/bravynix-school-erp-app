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

  group('writing', () {
    test('creates an event for the Society, which names no Institution', () async {
      final (:repository, :adapter) = build(() => okReply(eventJson(), status: 201));
      await repository.create(planEvent, scope: EventScope.society);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['POST', '/v1/events']);
      expect(bodyOf(request), {
        'title': 'Sports Day',
        'startDate': '2026-12-05',
        'endDate': '2026-12-05',
        'durationLabel': '1 Day Event',
        'description': null,
        'venue': null,
        'audience': 1,
        'presetImageCode': null,
        'isHoliday': false,
        'holidayType': null,
        'holidayForStudents': false,
        'holidayForStaff': false,
        'holidayPredefinedClassIds': <String>[],
        'scope': 1,
      });
    });

    test('creates an event for an Institution, with a picture and a holiday for some classes', () async {
      final (:repository, :adapter) = build(() => okReply(eventJson(isHoliday: true), status: 201));
      final input = EventInput(
        title: 'Diwali break',
        startDate: DateTime(2026, 11, 8),
        endDate: DateTime(2026, 11, 10),
        durationLabel: '3 Days Holiday',
        audience: EventAudience.studentsAndParents,
        description: 'School reopens on the 11th.',
        venue: 'Campus',
        presetImageCode: 'festival',
        isHoliday: true,
        holidayType: HolidayType.vacation,
        holidayForStudents: true,
        holidayClassIds: const ['c1', 'c2'],
      );
      await repository.create(input, scope: EventScope.institution, institutionId: 'i1');
      expect(bodyOf(adapter.requests.single), {
        'title': 'Diwali break',
        'startDate': '2026-11-08',
        'endDate': '2026-11-10',
        'durationLabel': '3 Days Holiday',
        'description': 'School reopens on the 11th.',
        'venue': 'Campus',
        'audience': 2,
        'presetImageCode': 'festival',
        'isHoliday': true,
        'holidayType': 2,
        'holidayForStudents': true,
        'holidayForStaff': false,
        'holidayPredefinedClassIds': ['c1', 'c2'],
        'scope': 2,
        'institutionId': 'i1',
      });
    });

    test('a holiday for staff alone names no classes, and a plain event no holiday at all', () async {
      final (:repository, :adapter) = build(() => okReply(eventJson(), status: 201));
      final staffHoliday = EventInput(
        title: 'Staff day',
        startDate: DateTime(2026, 12, 5),
        endDate: DateTime(2026, 12, 5),
        durationLabel: '1 Day Holiday',
        audience: EventAudience.staff,
        isHoliday: true,
        holidayType: HolidayType.optional,
        holidayForStaff: true,
        // Left over from a time the holiday was for students: not sent.
        holidayClassIds: const ['c1'],
      );
      await repository.create(staffHoliday, scope: EventScope.society);
      final body = bodyOf(adapter.requests.single);
      expect(
        [body['holidayForStudents'], body['holidayForStaff'], body['holidayPredefinedClassIds']],
        [false, true, <String>[]],
      );
      final plain = EventInput(
        title: 'Talk',
        startDate: DateTime(2026, 12, 5),
        endDate: DateTime(2026, 12, 5),
        durationLabel: '1 Day Event',
        audience: EventAudience.everyone,
        holidayType: HolidayType.vacation,
        holidayForStudents: true,
        holidayClassIds: const ['c1'],
      );
      await repository.create(plain, scope: EventScope.society);
      final other = bodyOf(adapter.requests.last);
      expect(
        [other['isHoliday'], other['holidayType'], other['holidayForStudents'], other['holidayPredefinedClassIds']],
        [false, null, false, <String>[]],
      );
    });

    test('changes an event with the version that was read, and every field, which clears what is empty', () async {
      final (:repository, :adapter) = build(() => okReply(eventJson()));
      await repository.change(schoolEvent(), planEvent);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['PATCH', '/v1/events/e1']);
      final body = bodyOf(request);
      expect(body['version'], 1);
      expect(body['title'], 'Sports Day');
      expect(body.containsKey('description'), isTrue);
      expect(body['description'], isNull);
      expect(body.containsKey('scope'), isFalse);
    });

    test('moves an event to the Society with the version that was read, and to an Institution by name', () async {
      final (:repository, :adapter) = build(() => okReply(eventJson()));
      await repository.changeScope(
        schoolEvent(scope: EventScope.institution, institutionId: 'i1'),
        scope: EventScope.society,
      );
      final toSociety = adapter.requests.single;
      expect([toSociety.method, toSociety.uri.path], ['POST', '/v1/events/e1/scope']);
      expect(bodyOf(toSociety), {'version': 1, 'scope': 1});
      final event = await repository.changeScope(schoolEvent(), scope: EventScope.institution, institutionId: 'i2');
      expect(bodyOf(adapter.requests.last), {'version': 1, 'scope': 2, 'institutionId': 'i2'});
      expect(event.scope, EventScope.institution);
    });

    test('removes an event', () async {
      final (:repository, :adapter) = build(() => okReply({'id': 'e1', 'status': 0}));
      await repository.remove('e1');
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['DELETE', '/v1/events/e1']);
    });
  });
}
