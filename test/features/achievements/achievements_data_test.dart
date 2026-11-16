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

  Map<String, Object?> star(String id, int tier, String description, String by) => {
    'id': id,
    'studentId': 'p1',
    'academicYearId': 'y1',
    'tier': tier,
    'description': description,
    'awardedByStaffMemberId': 't1',
    'createdBy': by,
    'createdAt': '2026-11-12T08:00:00.000Z',
    'version': 1,
  };

  group('ACH-01', () {
    test('reads the counts and the stars, newest first as the server sends them', () async {
      final (:repository, :adapter) = build(
        () => okReply({
          'stars': {'total': 2, 'silver': 1, 'gold': 1, 'platinum': 0},
          'achievements': [star('a2', 2, 'Won the quiz', 'u2'), star('a1', 1, 'Helped', 't1')],
        }),
      );
      final stars = await repository.stars('p1');
      expect([stars.total, stars.silver, stars.gold, stars.platinum], [2, 1, 1, 0]);
      expect(
        [for (final a in stars.achievements) (a.id, a.tier, a.description, a.createdBy)],
        [
          ('a2', StarTier.gold, 'Won the quiz', 'u2'),
          ('a1', StarTier.silver, 'Helped', 't1'),
        ],
      );
      expect(stars.achievements.first.createdAt, DateTime.utc(2026, 11, 12, 8));
      final request = adapter.requests.single;
      expect([request.method, request.uri.path], ['GET', '/v1/students/p1/achievements']);
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

    test('keeps the code of a refusal', () async {
      final (:repository, adapter: _) = build(() => errorReply(403, 'FORBIDDEN'));
      await expectLater(
        repository.remove('a1'),
        throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'FORBIDDEN')),
      );
    });
  });
}
