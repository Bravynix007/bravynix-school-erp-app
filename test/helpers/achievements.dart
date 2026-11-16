import 'package:bravynix_school_erp/features/achievements/domain/achievement.dart';

/// A silver star the teacher `t1` gave.
final silverStar = Achievement(
  id: 'a1',
  tier: StarTier.silver,
  description: 'Helped a classmate',
  createdBy: 't1',
  createdAt: DateTime.utc(2026, 11, 10, 8),
);

/// A gold star the Admin `u2` gave.
final goldStar = Achievement(
  id: 'a2',
  tier: StarTier.gold,
  description: 'Won the quiz',
  createdBy: 'u2',
  createdAt: DateTime.utc(2026, 11, 12, 8),
);

/// A silver star no person gave (API design 7.6: the author is "System", with no ID).
final systemStar = Achievement(
  id: 'a3',
  tier: StarTier.silver,
  description: 'Seeded',
  createdBy: null,
  createdAt: DateTime.utc(2026, 11, 9, 8),
);

/// The two stars, as ACH-01 counts them.
final twoStars = Stars(total: 2, silver: 1, gold: 1, platinum: 0, achievements: [goldStar, silverStar]);

/// A student with no star yet.
const noStars = Stars(total: 0, silver: 0, gold: 0, platinum: 0, achievements: []);
