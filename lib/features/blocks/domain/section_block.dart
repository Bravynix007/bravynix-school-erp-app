import 'package:equatable/equatable.dart';

/// What a block stops (API design 10.4e): a Society's Owners, or the staff or the parents of one Institution.
enum BlockSection {
  owners,
  staff,
  students;

  static BlockSection? fromName(Object? name) {
    for (final section in values) {
      if (section.name == name) return section;
    }
    return null;
  }
}

/// One active block of the Owner's own Society, with the reason Super Admin gave (SOC-02).
class SectionBlock extends Equatable {
  const new({
    required this.id,
    required this.section,
    required this.reason,
    required this.blockedAt,
    this.institutionId,
    this.institutionName,
  });

  final String id;
  final BlockSection section;

  /// Null for the Owners' block.
  final String? institutionId;
  final String? institutionName;
  final String reason;
  final DateTime blockedAt;

  @override
  List<Object?> get props => [id, section, institutionId, institutionName, reason, blockedAt];
}
