import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/achievements/data/achievement_models.dart';
import 'package:bravynix_school_erp/features/achievements/domain/achievement.dart';
import 'package:bravynix_school_erp/features/achievements/domain/achievements_repository.dart';

class AchievementsRepositoryImpl implements AchievementsRepository {
  const new({required this._api});

  final ApiClient _api;

  static String _of(String studentId) => 'students/${Uri.encodeComponent(studentId)}/achievements';

  @override
  Future<Stars> stars(String studentId) => _api.data(_of(studentId), parse: AchievementModels.stars);

  @override
  Future<Achievement> give(
    String studentId, {
    required StarTier tier,
    required String description,
  }) => _api.data(
    _of(studentId),
    method: HttpMethod.post,
    body: {'tier': tier.code, 'description': description},
    parse: AchievementModels.achievement,
  );

  @override
  Future<void> remove(String achievementId) => _api.data(
    'achievements/${Uri.encodeComponent(achievementId)}',
    method: HttpMethod.delete,
    parse: (_) {},
  );
}
