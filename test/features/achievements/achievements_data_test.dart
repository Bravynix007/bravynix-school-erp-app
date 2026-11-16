import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/achievements/data/achievements_repository_impl.dart';
import 'package:bravynix_school_erp/features/achievements/domain/achievement.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({AchievementsRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: AchievementsRepositoryImpl(api: api), adapter: adapter);
  }

  Map<String, Object?> star(String id, int tier, String description, String? by) => {
    'id': id,
    'studentId': 'p1',
    'academicYearId': 'y1',
    'tier': tier,
    'description': description,
    'awardedByStaffMemberId': 't1',
    // The person shape of API design 7.6; a background job's row is "System" with no ID.
    'createdBy': by == null
        ? {'id': null, 'displayName': 'System', 'roleName': null}
        : {'id': by, 'displayName': 'R. Nair', 'roleName': 'Teacher'},
    'createdAt': '2026-11-12T08:00:00.000Z',
    'version': 1,
  };

  group('ACH-01', () {
    test('reads the counts and the stars, newest first as the server sends them', () async {
      final (:repository, :adapter) = build(
        () => okReply({
          'stars': {'total': 6, 'silver': 3, 'gold': 1, 'platinum': 2},
          'achievements': [
            star('a2', 2, 'Won the quiz', 'u2'),
            star('a1', 1, 'Helped', 't1'),
            star('a0', 1, 'Seeded', null),
          ],
        }),
      );
      final stars = await repository.stars('p1');
      expect([stars.total, stars.silver, stars.gold, stars.platinum], [6, 3, 1, 2]);
      expect(
        [for (final a in stars.achievements) (a.id, a.tier, a.description, a.createdBy)],
        [
          ('a2', StarTier.gold, 'Won the quiz', 'u2'),
          ('a1', StarTier.silver, 'Helped', 't1'),
          ('a0', StarTier.silver, 'Seeded', null),
        ],
      );
      expect(stars.achievements.first.createdAt, DateTime.utc(2026, 11, 12, 8));
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['GET', '/v1/students/p1/achievements']);
    });

    test('encodes the ID of the student in the path', () async {
      final (:repository, :adapter) = build(
        () => okReply({
          'stars': {'total': 0, 'silver': 0, 'gold': 0, 'platinum': 0},
          'achievements': <Object?>[],
        }),
      );
      await repository.stars('p/1');
      expect(adapter.requests.single.uri.path, '/v1/students/p%2F1/achievements');
    });

    test('keeps the code of a refusal', () async {
      final (:repository, adapter: _) = build(() => errorReply(403, 'NOT_ASSIGNED'));
      await expectLater(
        repository.stars('p1'),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'NOT_ASSIGNED')),
      );
    });
  });

  group('ACH-02', () {
    test('sends the kind as its number and the words, and answers with the star', () async {
      final (:repository, :adapter) = build(
        () => okReply(star('a3', 3, 'Led the assembly', 't1'), code: 'CREATED', status: 201),
      );
      final given = await repository.give('p1', tier: StarTier.platinum, description: 'Led the assembly');
      expect([given.id, given.tier, given.description], ['a3', StarTier.platinum, 'Led the assembly']);
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['POST', '/v1/students/p1/achievements']);
      expect(bodyOf(request), {'tier': 3, 'description': 'Led the assembly'});
    });

    test('encodes the ID of the student in the path', () async {
      final (:repository, :adapter) = build(
        () => okReply(star('a3', 1, 'Helped', 't1'), code: 'CREATED', status: 201),
      );
      await repository.give('p/1', tier: StarTier.silver, description: 'Helped');
      expect(adapter.requests.single.uri.path, '/v1/students/p%2F1/achievements');
    });

    test('keeps the code of a refusal', () async {
      final (:repository, adapter: _) = build(() => errorReply(422, 'NO_CURRENT_PLACEMENT'));
      await expectLater(
        repository.give('p1', tier: StarTier.silver, description: 'x'),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'NO_CURRENT_PLACEMENT')),
      );
    });
  });

  group('ACH-03', () {
    test('deletes the star by its ID', () async {
      final (:repository, :adapter) = build(() => okReply(null));
      await repository.remove('a1');
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['DELETE', '/v1/achievements/a1']);
    });

    test('encodes the ID of the star in the path', () async {
      final (:repository, :adapter) = build(() => okReply(null));
      await repository.remove('a/1');
      expect(adapter.requests.single.uri.path, '/v1/achievements/a%2F1');
    });

    test('keeps the code of a refusal', () async {
      final (:repository, adapter: _) = build(() => errorReply(403, 'FORBIDDEN'));
      await expectLater(
        repository.remove('a1'),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'FORBIDDEN')),
      );
    });
  });
}
