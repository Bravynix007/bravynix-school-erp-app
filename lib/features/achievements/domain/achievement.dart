import 'package:equatable/equatable.dart';

/// The kind of star (PRD 7.6, API design 10.5d): 1 Silver, 2 Gold, 3 Platinum.
enum StarTier {
  silver(1),
  gold(2),
  platinum(3);

  new(this.code);

  final int code;

  /// Null for a number the app does not know.
  static StarTier? fromCode(Object? code) {
    for (final tier in values) {
      if (tier.code == code) return tier;
    }
    return null;
  }
}

/// One star given to a student, as ACH-01 lists it.
class Achievement extends Equatable {
  const new({
    required this.id,
    required this.tier,
    required this.description,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;

  /// Null when the API sends a tier this app does not know yet: it still counts in the total.
  final StarTier? tier;
  final String description;

  /// The ID of the person who gave the star, null for one a background job made: a teacher may take back only their
  /// own.
  final String? createdBy;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, tier, description, createdBy, createdAt];
}

/// The stars a student has earned, and the list they come from, newest first (ACH-01).
class Stars extends Equatable {
  const new({
    required this.total,
    required this.silver,
    required this.gold,
    required this.platinum,
    required this.achievements,
  });

  final int total;
  final int silver;
  final int gold;
  final int platinum;
  final List<Achievement> achievements;

  int countOf(StarTier tier) => switch (tier) {
    StarTier.silver => silver,
    StarTier.gold => gold,
    StarTier.platinum => platinum,
  };

  @override
  List<Object?> get props => [total, silver, gold, platinum, achievements];
}
