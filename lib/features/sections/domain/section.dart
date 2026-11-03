import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:equatable/equatable.dart';

/// One section of a class: a predefined section (A, B, ...) under a name the school gives it (API design 10.4j).
class Section extends Equatable {
  const new({
    required this.id,
    required this.classId,
    required this.predefinedSection,
    required this.displayName,
    required this.version,
    this.capacity,
    this.currentStudentCount,
  });

  final String id;
  final String classId;
  final NamedRef predefinedSection;
  final String displayName;

  /// How many students the section is meant for. Only a warning: no operation refuses a number of students.
  final int? capacity;

  /// The students placed in the section; null until the People module (Phase 4) exists.
  final int? currentStudentCount;

  /// What a change must send back, so one made meanwhile is told apart (409 VERSION_CONFLICT).
  final int version;

  @override
  List<Object?> get props => [id, classId, predefinedSection, displayName, capacity, currentStudentCount, version];
}

/// The most students a section's capacity can be (API design 10.4j).
const maxSectionCapacity = 32767;
