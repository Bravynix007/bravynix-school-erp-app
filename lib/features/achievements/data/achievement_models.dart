import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/achievements/domain/achievement.dart';

/// JSON → domain for ACH-01 and ACH-02. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class AchievementModels {
  static Achievement achievement(Object? raw) {
    final json = jsonObject(raw);
    return Achievement(
      id: json['id'] as String,
      tier: StarTier.fromCode(json['tier']),
      description: json['description'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static Stars stars(Object? raw) {
    final json = jsonObject(raw);
    final counts = jsonObject(json['stars']);
    return Stars(
      total: (counts['total'] as num).toInt(),
      silver: (counts['silver'] as num).toInt(),
      gold: (counts['gold'] as num).toInt(),
      platinum: (counts['platinum'] as num).toInt(),
      achievements: [
        for (final item in jsonList(json['achievements'])) achievement(item),
      ],
    );
  }
}
