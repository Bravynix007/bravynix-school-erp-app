import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:equatable/equatable.dart';

/// Where promoted students go (STU-09, PRM-01): the year, class and section. A promotion without one is the
/// completion of the final class.
class PromotionTarget extends Equatable {
  const new({required this.academicYearId, required this.classId, required this.sectionId});

  final String academicYearId;
  final String classId;
  final String sectionId;

  @override
  List<Object?> get props => [academicYearId, classId, sectionId];
}

/// One student promoted (STU-09): the profile, which shows the new placement, and the second looks the server asked
/// for (`SECTION_OVER_CAPACITY`).
class Promoted extends Equatable {
  const new(this.record, {this.warnings = const []});

  final StudentRecord record;
  final List<String> warnings;

  @override
  List<Object?> get props => [record, warnings];
}

/// Why a student of a promotion was left where they were (PRM-01).
enum SkipReason {
  /// Not an active student placed in the class or section that was promoted.
  notInSource('NOT_IN_SOURCE'),

  /// Already holds an enrolment in the target year.
  alreadyEnrolled('ALREADY_ENROLLED');

  new(this.code);

  final String code;

  static SkipReason? fromCode(Object? code) {
    for (final reason in values) {
      if (reason.code == code) return reason;
    }
    return null;
  }
}

/// What a class or section promotion did (PRM-01): how many were promoted, how many were left, and the warnings.
class PromotionResult extends Equatable {
  const new({required this.promotedCount, this.skipped = const [], this.warnings = const []});

  final int promotedCount;

  /// The reason of each student left where they were, in the order the server gave them.
  final List<SkipReason> skipped;
  final List<String> warnings;

  int skippedFor(SkipReason reason) => skipped.where((skip) => skip == reason).length;

  @override
  List<Object?> get props => [promotedCount, skipped, warnings];
}
