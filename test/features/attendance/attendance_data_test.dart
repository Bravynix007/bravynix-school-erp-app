import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/features/attendance/data/attendance_models.dart';
import 'package:bravynix_school_erp/features/attendance/data/attendance_repository_impl.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/attendance.dart';
import '../../helpers/fake_http.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({AttendanceRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: AttendanceRepositoryImpl(api: api), adapter: adapter);
  }

  group('marks', () {
    test('are numbered 1 Present to 5 Leave, as the API numbers them', () {
      expect([for (final mark in AttendanceMark.values) mark.code], [1, 2, 3, 4, 5]);
      expect(AttendanceMarkCode.fromCode(4), AttendanceMark.halfDay);
      expect(AttendanceMarkCode.fromCode(5), AttendanceMark.leave);
      expect(AttendanceMarkCode.fromCode(0), isNull);
      expect(AttendanceMarkCode.fromCode(6), isNull);
    });
  });

  group('models', () {
    test('read the classes with their sections, named as the pickers name them', () {
      final choices = AttendanceModels.sections([
        {
          'classId': 'c7',
          'className': '7th',
          'sections': [
            {'id': 'sec1', 'displayName': 'A'},
            {'id': 'sec2', 'displayName': 'B'},
          ],
        },
        {
          'classId': 'c8',
          'className': '8th',
          'sections': [
            {'id': 'sec3', 'displayName': 'A'},
          ],
        },
      ]);
      expect(choices, twoClasses);
    });

    test('read a roll with the marks of a register, and who took it', () {
      final roll = AttendanceModels.roster(
        rosterJson(
          canMark: false,
          students: [
            studentJson(),
            studentJson(enrolment: 'e2', student: 's2', roll: '2', firstName: 'Bea', lastName: null, status: 2),
          ],
          session: {
            'id': 'r1',
            'version': 2,
            'submittedBy': {'id': 'p1', 'displayName': 'R. Nair'},
            'submittedAt': '2026-11-17T04:30:00.000Z',
          },
        ),
      );
      expect(roll.sectionId, 'sec1');
      expect(roll.day, '2026-11-17');
      expect(roll.canMark, isFalse);
      expect(
        roll.taken,
        TakenRegister(id: 'r1', version: 2, takenBy: 'R. Nair', takenAt: DateTime.utc(2026, 11, 17, 4, 30)),
      );
      expect(roll.students.map((student) => student.mark), [AttendanceMark.present, AttendanceMark.absent]);
      expect(roll.students.last.fullName, 'Bea');
      expect(roll.students.first.fullName, 'Asha Rao');
    });

    test('read a holiday, and a day with no register', () {
      final roll = AttendanceModels.roster(rosterJson(isHoliday: true, holidayTitle: 'Founders Day', canMark: false));
      expect([roll.isHoliday, roll.holidayTitle, roll.canMark, roll.taken], [true, 'Founders Day', false, null]);
    });

    test('refuse a status they do not know instead of showing a wrong mark', () {
      expect(
        () => AttendanceModels.roster(rosterJson(students: [studentJson(status: 9)])),
        throwsFormatException,
      );
      expect(() => AttendanceModels.roster(rosterJson(students: [studentJson(status: 0)])), throwsFormatException);
    });

    test('refuse an answer they cannot read', () {
      expect(() => AttendanceModels.sections({'a': 1}), throwsFormatException);
      expect(() => AttendanceModels.roster({...rosterJson(), 'canMark': null}), throwsA(isA<TypeError>()));
    });

    test('read the number of students a register counts', () {
      expect(AttendanceModels.rosterCount(countsJson()), submitted);
    });

    test('write a register and a correction with the numbers of the marks', () {
      const marks = [
        MarkChange(enrolmentId: 'e1', mark: AttendanceMark.late),
        MarkChange(enrolmentId: 'e2', mark: AttendanceMark.present),
      ];
      expect(AttendanceModels.submitBody(sectionId: 'sec1', day: '2026-11-17', rosterCount: 3, exceptions: marks), {
        'sectionId': 'sec1',
        'attendanceDate': '2026-11-17',
        'rosterCount': 3,
        'exceptions': [
          {'studentEnrolmentId': 'e1', 'attendanceStatus': 3},
          {'studentEnrolmentId': 'e2', 'attendanceStatus': 1},
        ],
      });
      expect(AttendanceModels.correctBody(4, marks), {
        'version': 4,
        'changes': [
          {'studentEnrolmentId': 'e1', 'attendanceStatus': 3},
          {'studentEnrolmentId': 'e2', 'attendanceStatus': 1},
        ],
      });
    });
  });

  group('repository', () {
    test('reads the sections to pick from, for the Institution', () async {
      final t = build(() => okReply([]));
      expect(await t.repository.sections('i1'), const MarkingSections(classes: [], sections: []));
      expect(t.adapter.requests.single.method, 'GET');
      expect(t.adapter.paths.single, '/v1/attendance/sections');
      expect(t.adapter.requests.single.uri.queryParameters, {'institutionId': 'i1'});
    });

    test('reads a roll for a section and day', () async {
      final t = build(() => okReply(rosterJson()));
      expect((await t.repository.roster('sec1', '2026-11-17')).students, hasLength(2));
      expect(t.adapter.paths.single, '/v1/attendance/roster');
      expect(t.adapter.requests.single.uri.queryParameters, {'sectionId': 'sec1', 'date': '2026-11-17'});
    });

    test('submits with the Idempotency-Key and only the students who are not Present', () async {
      final t = build(() => okReply(countsJson(), code: 'ATTENDANCE_SUBMITTED', status: 201));
      final counts = await t.repository.submit(
        sectionId: 'sec1',
        day: '2026-11-17',
        rosterCount: 3,
        exceptions: const [MarkChange(enrolmentId: 'e2', mark: AttendanceMark.absent)],
        idempotencyKey: 'key-1',
      );
      expect(counts, submitted);
      final request = t.adapter.requests.single;
      expect([request.method, request.uri.path], ['POST', '/v1/attendance/sessions']);
      expect(request.headers['Idempotency-Key'], 'key-1');
      expect(bodyOf(request)['exceptions'], [
        {'studentEnrolmentId': 'e2', 'attendanceStatus': 2},
      ]);
    });

    test('corrects a register with its version, and voids it with a reason', () async {
      final t = build(() => okReply(countsJson(version: 3)));
      await t.repository.correct('r1', 2, const [MarkChange(enrolmentId: 'e2', mark: AttendanceMark.present)]);
      await t.repository.voidRegister('r1', 3, 'Taken for the wrong section');
      final [correction, voiding] = t.adapter.requests;
      expect([correction.method, correction.uri.path], ['PATCH', '/v1/attendance/sessions/r1/marks']);
      expect(bodyOf(correction)['version'], 2);
      expect([voiding.method, voiding.uri.path], ['POST', '/v1/attendance/sessions/r1/void']);
      expect(bodyOf(voiding), {'version': 3, 'reason': 'Taken for the wrong section'});
    });

    test('passes on the refusal with the details a screen needs', () async {
      final t = build(
        () => errorReply(
          409,
          'ATTENDANCE_ALREADY_SUBMITTED',
          extra: {
            'data': {'sessionId': 'r1'},
          },
        ),
      );
      await expectLater(
        t.repository.submit(
          sectionId: 'sec1',
          day: '2026-11-17',
          rosterCount: 3,
          exceptions: const [],
          idempotencyKey: 'k',
        ),
        throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', 'ATTENDANCE_ALREADY_SUBMITTED')),
      );
    });
  });
}
