import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/time_slots/data/time_slot_models.dart';
import 'package:bravynix_school_erp/features/time_slots/data/time_slots_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/time_slots.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({TimeSlotsRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: TimeSlotsRepositoryImpl(api: api), adapter: adapter);
  }

  group('models', () {
    test('read a period, with or without a label, and a list, ignoring the fields they do not show', () {
      expect(TimeSlotModels.slot(timeSlotJson()), firstPeriod);
      expect(
        TimeSlotModels.slots([
          timeSlotJson(),
          timeSlotJson(
            id: 't2',
            periodNo: 4,
            startTime: '12:00',
            endTime: '12:30',
            isBreak: true,
            label: 'Lunch',
            version: 1,
          ),
        ]),
        [firstPeriod, lunch],
      );
    });

    test('refuse an answer they cannot read instead of showing a wrong period', () {
      expect(() => TimeSlotModels.slot('x'), throwsFormatException);
      expect(() => TimeSlotModels.slots({'a': 1}), throwsFormatException);
      expect(() => TimeSlotModels.slot({...timeSlotJson(), 'periodNo': null}), throwsA(isA<TypeError>()));
    });

    test('send the Institution and the fields to add, leaving a missing label out', () {
      expect(
        TimeSlotModels.createBody('i1', periodNo: 1, startTime: '09:00', endTime: '09:45', isBreak: false),
        {'institutionId': 'i1', 'periodNo': 1, 'startTime': '09:00', 'endTime': '09:45', 'isBreak': false},
      );
      expect(
        TimeSlotModels.createBody(
          'i1',
          periodNo: 4,
          startTime: '12:00',
          endTime: '12:30',
          isBreak: true,
          label: 'Lunch',
        ),
        {
          'institutionId': 'i1',
          'periodNo': 4,
          'startTime': '12:00',
          'endTime': '12:30',
          'isBreak': true,
          'label': 'Lunch',
        },
      );
    });

    test('send the version with the times to change, and null to clear the label', () {
      expect(TimeSlotModels.updateBody(lunch, startTime: '12:05', endTime: '12:35'), {
        'version': 1,
        'startTime': '12:05',
        'endTime': '12:35',
        'label': null,
      });
    });
  });

  group('repository', () {
    test('lists the periods of the Institution from TTS-01', () async {
      final (:repository, :adapter) = build(() => okReply([timeSlotJson()]));
      expect(await repository.slots('i1'), [firstPeriod]);
      expect(adapter.requests.single.uri.toString(), 'http://api.test/v1/timetable/time-slots?institutionId=i1');
    });

    test('adds a period with TTS-02', () async {
      final (:repository, :adapter) = build(() => okReply(timeSlotJson(), status: 201));
      expect(
        await repository.create('i1', periodNo: 1, startTime: '09:00', endTime: '09:45', isBreak: false),
        firstPeriod,
      );
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.paths, ['/v1/timetable/time-slots']);
      expect(adapter.requests.single.data, containsPair('periodNo', 1));
    });

    test('changes a period with TTS-03, sending the version it read', () async {
      final (:repository, :adapter) = build(() => okReply(timeSlotJson(version: 3)));
      await repository.update(firstPeriod, startTime: '09:05', endTime: '09:50', label: 'First');
      expect(adapter.paths, ['/v1/timetable/time-slots/t1']);
      expect(adapter.requests.single.method, 'PATCH');
      expect(adapter.requests.single.data, {
        'version': 2,
        'startTime': '09:05',
        'endTime': '09:50',
        'label': 'First',
      });
    });

    test('deactivates a period with TTS-04, encoding the ID it puts in the path', () async {
      final (:repository, :adapter) = build(() => okReply({'id': 'a/b', 'status': 0}));
      await repository.deactivate('a/b');
      expect(adapter.paths, ['/v1/timetable/time-slots/a%2Fb']);
      expect(adapter.requests.single.method, 'DELETE');
    });

    test('turns a refusal into an ApiFailure for the screen', () async {
      for (final (status, code) in [(409, 'TIME_SLOT_IN_USE'), (422, 'CURRENT_YEAR_REQUIRED'), (404, 'NOT_FOUND')]) {
        final (:repository, adapter: _) = build(() => errorReply(status, code));
        await expectLater(
          repository.deactivate('t1'),
          throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', code)),
        );
      }
    });
  });
}
