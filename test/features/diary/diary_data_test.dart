import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/diary/data/diary_models.dart';
import 'package:bravynix_school_erp/features/diary/data/diary_repository_impl.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/diary.dart';
import '../../helpers/fake_http.dart';
import '../../helpers/subjects.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({DiaryRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: DiaryRepositoryImpl(api: api), adapter: adapter);
  }

  group('models', () {
    test('read an entry with its subject, its day and who wrote it', () {
      expect(DiaryModels.entry(diaryJson()), mathsEntry);
    });

    test('read an entry an Admin with no staff record wrote, which has no teacher', () {
      final entry = DiaryModels.entry(
        diaryJson(id: 'd3', description: 'Tomorrow is a half day.', teacher: null),
      );
      expect(entry, noticeEntry);
      expect([entry.teacherId, entry.teacherName], everyElement(isNull));
    });

    test("read a parent's entry, where the section has no names", () {
      final entry = DiaryModels.entry({...diaryJson(), 'sectionName': null, 'className': null});
      expect(entry, mathsEntry);
    });

    test('read the entries in the order they come', () {
      expect(
        DiaryModels.entries([
          diaryJson(),
          diaryJson(
            id: 'd2',
            version: 3,
            subjectId: 'u2',
            subject: 'Art',
            description: 'Bring crayons.',
            teacher: {'id': 't2', 'displayName': 'S. Iyer'},
          ),
        ]),
        [mathsEntry, artEntry],
      );
    });

    test('write an entry as DIA-02 takes it', () {
      expect(
        DiaryModels.createBody(
          'sec1',
          const DiaryInput(subjectId: 'u1', day: '2026-11-16', description: 'Read chapter 3.'),
        ),
        {'sectionId': 'sec1', 'subjectId': 'u1', 'diaryDate': '2026-11-16', 'description': 'Read chapter 3.'},
      );
    });

    test('write only what a change touched, with the version that was read', () {
      DiaryInput input({String? subject, String? day, String? description}) => DiaryInput(
        subjectId: subject ?? mathsEntry.subjectId,
        day: day ?? mathsEntry.day,
        description: description ?? mathsEntry.description,
      );
      expect(DiaryModels.changeBody(mathsEntry, input()), {'version': 1});
      expect(DiaryModels.changeBody(mathsEntry, input(description: 'Exercise 4.3.')), {
        'version': 1,
        'description': 'Exercise 4.3.',
      });
      expect(DiaryModels.changeBody(mathsEntry, input(subject: 'u2', day: '2026-11-16')), {
        'version': 1,
        'subjectId': 'u2',
        'diaryDate': '2026-11-16',
      });
    });
  });

  group('repository', () {
    test('reads the entries of a section on a day', () async {
      final t = build(() => okReply([diaryJson()]));
      expect(await t.repository.ofSection('sec1', '2026-11-17'), [mathsEntry]);
      expect(t.adapter.requests.single.method, 'GET');
      expect(t.adapter.paths.single, '/v1/diary-entries');
      expect(t.adapter.requests.single.uri.queryParameters, {'sectionId': 'sec1', 'date': '2026-11-17'});
    });

    test("reads a child's entries on a day, which names the student and not the section", () async {
      final t = build(() => okReply([diaryJson()]));
      expect(await t.repository.ofChild('s1', '2026-11-17'), [mathsEntry]);
      expect(t.adapter.requests.single.uri.queryParameters, {'studentId': 's1', 'date': '2026-11-17'});
    });

    test('reads the subjects the caller may write for in a section, as subjects are read', () async {
      final t = build(() => okReply([subjectJson(), subjectJson(id: 'u2', name: 'Art', code: null, version: 1)]));
      expect(await t.repository.subjects('sec1'), [maths, art]);
      expect(t.adapter.requests.single.method, 'GET');
      expect(t.adapter.paths.single, '/v1/diary-subjects');
      expect(t.adapter.requests.single.uri.queryParameters, {'sectionId': 'sec1'});
    });

    test('adds an entry', () async {
      final t = build(() => okReply(diaryJson(), code: 'DIARY_ENTRY_CREATED', status: 201));
      final entry = await t.repository.add(
        'sec1',
        const DiaryInput(subjectId: 'u1', day: '2026-11-17', description: 'Exercise 4.2, questions 1 to 5.'),
      );
      expect(entry, mathsEntry);
      final request = t.adapter.requests.single;
      expect([request.method, request.uri.path], ['POST', '/v1/diary-entries']);
      expect(bodyOf(request), {
        'sectionId': 'sec1',
        'subjectId': 'u1',
        'diaryDate': '2026-11-17',
        'description': 'Exercise 4.2, questions 1 to 5.',
      });
    });

    test('changes an entry with the version that was read', () async {
      final t = build(() => okReply(diaryJson(version: 2, description: 'Exercise 4.3.')));
      final entry = await t.repository.change(
        mathsEntry,
        const DiaryInput(subjectId: 'u1', day: '2026-11-17', description: 'Exercise 4.3.'),
      );
      expect(entry.version, 2);
      final request = t.adapter.requests.single;
      expect([request.method, request.uri.path], ['PATCH', '/v1/diary-entries/d1']);
      expect(bodyOf(request), {'version': 1, 'description': 'Exercise 4.3.'});
    });

    test('removes an entry', () async {
      final t = build(() => okReply({'id': 'd1', 'status': 0}));
      await t.repository.remove('d1');
      final request = t.adapter.requests.single;
      expect([request.method, request.uri.path], ['DELETE', '/v1/diary-entries/d1']);
    });
  });
}
