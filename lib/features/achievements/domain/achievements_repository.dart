import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/achievements/domain/achievement.dart';

/// The stars of students (API design 10.5d). Methods throw [ApiFailure].
abstract class AchievementsRepository {
  /// ACH-01: the stars of a student, with the counts of each kind. 403 `NOT_ASSIGNED` for a teacher whose sections do
  /// not hold the student, 403 `FORBIDDEN` for a role that may not, 404 for a student outside the caller's reach.
  Future<Stars> stars(String studentId);

  /// ACH-02: gives one star of [tier], for a [description] of 1 to 500 characters. 404 for a deactivated student; 422
  /// `NO_CURRENT_PLACEMENT` when the student sits in no section now; 403 `NOT_ASSIGNED` as ACH-01.
  Future<Achievement> give(
    String studentId, {
    required StarTier tier,
    required String description,
  });

  /// ACH-03: takes a star back. 403 `FORBIDDEN` for a teacher and a star another gave, 404 for a star that is gone.
  Future<void> remove(String achievementId);
}
