import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/timetable/data/timetable_models.dart';
import 'package:bravynix_school_erp/features/timetable/data/timetable_repository_impl.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_week.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/timetable.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({TimetableRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: TimetableRepositoryImpl(api: api), adapter: adapter);
  }

  group('models', () {
    test('read a lesson, a named break and a parent’s entry that has no section name', () {
      expect(TimetableModels.entry(entryJson()), mathsMonday);
      expect(
        TimetableModels.entry(
          entryJson(
            id: 'x2',
            isBreak: true,
            subject: null,
            teacher: null,
            version: 3,
            timeSlot: const {'id': 't2', 'periodNo': 4, 'label': 'Lunch', 'startTime': '12:00', 'endTime': '12:30'},
          ),
        ),
        lunchMonday,
      );
      expect(TimetableModels.entry(entryJson(named: false)).sectionName, isNull);
      expect(TimetableModels.entry(entryJson(named: false)).classSection, isEmpty);
      expect(mathsMonday.classSection, '7th - A');
    });

    test('read a list, and refuse an answer they cannot read instead of showing a wrong week', () {
      expect(TimetableModels.entries([entryJson()]), [mathsMonday]);
      expect(() => TimetableModels.entries({'a': 1}), throwsFormatException);
      expect(() => TimetableModels.entry({...entryJson(), 'dayOfWeek': null}), throwsA(isA<TypeError>()));
      expect(() => TimetableModels.entry({...entryJson(), 'timeSlot': 'x'}), throwsFormatException);
    });

    test('ask for exactly one view of the week', () {
      expect(TimetableModels.query(const SectionWeek('sec1')), {'sectionId': 'sec1'});
      expect(TimetableModels.query(const OwnWeek('i1')), {'staffMemberId': 'me', 'institutionId': 'i1'});
      expect(TimetableModels.query(const ChildWeek('s1')), {'studentId': 's1'});
    });
  });

  group('repository', () {
    test('reads the week of a section, of a teacher and of a child from TT-01', () async {
      final (:repository, :adapter) = build(() => okReply([entryJson()]));
      expect(await repository.week(const SectionWeek('sec1')), [mathsMonday]);
      await repository.week(const OwnWeek('i1'));
      await repository.week(const ChildWeek('s1'));
      expect(
        [for (final request in adapter.requests) request.uri.toString()],
        [
          'http://api.test/v1/timetable/entries?sectionId=sec1',
          'http://api.test/v1/timetable/entries?staffMemberId=me&institutionId=i1',
          'http://api.test/v1/timetable/entries?studentId=s1',
        ],
      );
    });

    test('turns a refusal into an ApiFailure for the screen', () async {
      for (final (status, code) in [(403, 'NOT_ASSIGNED'), (422, 'CURRENT_YEAR_REQUIRED'), (423, 'SECTION_BLOCKED')]) {
        final (:repository, adapter: _) = build(() => errorReply(status, code));
        await expectLater(
          repository.week(const SectionWeek('sec1')),
          throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', code)),
        );
      }
    });
  });
}
