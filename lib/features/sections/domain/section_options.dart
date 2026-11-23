import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:equatable/equatable.dart';

/// The classes and the sections to choose a section from.
typedef SectionChoices = ({List<ClassChoice> classes, List<SectionChoice> sections});

/// A section to choose from (a staff member leads or teaches it, a student sits in it), with the class it is in.
class SectionChoice extends Equatable {
  const new({required this.id, required this.name, required this.classId});

  /// A section named after its class, "Class 5 · A".
  factory inClass({
    required String id,
    required String className,
    required String sectionName,
    required String classId,
  }) => SectionChoice(id: id, name: '$className · $sectionName', classId: classId);

  final String id;

  /// The class and the section, such as "Class 5 · A".
  final String name;

  final String classId;

  @override
  List<Object?> get props => [id, name, classId];
}

/// The sections of one class, out of the sections of an Institution.
extension SectionsInClass on List<SectionChoice> {
  /// The sections of the class [classId]; none while no class is chosen.
  List<SectionChoice> inClass(String? classId) => [
    for (final section in this)
      if (section.classId == classId) section,
  ];

  /// The name of the section [id], such as "Class 5 · A"; null when there is no such section in the list.
  String? nameOf(String? id) => where((section) => section.id == id).firstOrNull?.name;
}

/// A class that has sections, as it is shown to choose from.
class ClassChoice extends Equatable {
  const new({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// The academic years, the classes that have sections and the sections of one Institution, which the screens that pick
/// a year and a section (the class teacher, the teaching assignments, the students) choose from.
class SectionOptions extends Equatable {
  const new({required this.years, required this.sections, this.classes = const []});

  final List<AcademicYear> years;
  final List<SectionChoice> sections;
  final List<ClassChoice> classes;

  SectionChoices get choices => (classes: classes, sections: sections);

  /// The year to look at first: the current one, else the first; null when there is none.
  String? get firstYearId => years.where((year) => year.isCurrent).firstOrNull?.id ?? years.firstOrNull?.id;

  @override
  List<Object?> get props => [years, sections, classes];
}

/// Reads the [SectionOptions] of an Institution once for all the sections of a screen that need them, and again after
/// a failure (Try again).
class SectionOptionsSource {
  new({
    required this._years,
    required this._classes,
    required this._sections,
  });

  final AcademicYearsRepository _years;
  final ClassesRepository _classes;
  final SectionsRepository _sections;
  final _read = <String, Future<SectionOptions>>{};

  /// The years, and the sections of every class that has any, of the Institution. Throws what the repositories throw;
  /// the next read then tries again.
  Future<SectionOptions> read(String institutionId) async {
    final pending = _read[institutionId] ??= _fetch(institutionId);
    try {
      return await pending;
    } on Object {
      _read.removeWhere((_, read) => read == pending);
      rethrow;
    }
  }

  Future<SectionOptions> _fetch(String institutionId) async {
    final years = await _years.years(institutionId);
    final classes = await _classes.classes(institutionId);
    // A class without sections has nothing to read, and a teacher is refused the class where they have none (403
    // `NOT_ASSIGNED`, API design 10.4j): both are left out.
    final withSections = [
      for (final schoolClass in classes)
        if (schoolClass.sectionCount > 0) schoolClass,
    ];
    final bySection = await Future.wait([for (final schoolClass in withSections) _sectionsOf(schoolClass.id)]);
    final offered = [
      for (final (index, schoolClass) in withSections.indexed)
        if (bySection[index].isNotEmpty) (schoolClass, bySection[index]),
    ];
    return SectionOptions(
      years: years,
      classes: [
        for (final (schoolClass, _) in offered) ClassChoice(id: schoolClass.id, name: schoolClass.displayName),
      ],
      sections: [
        for (final (schoolClass, sections) in offered)
          for (final section in sections)
            SectionChoice.inClass(
              id: section.id,
              className: schoolClass.displayName,
              sectionName: section.displayName,
              classId: schoolClass.id,
            ),
      ],
    );
  }

  Future<List<Section>> _sectionsOf(String classId) async {
    try {
      return await _sections.sections(classId);
    } on ApiFailure catch (failure) {
      if (failure.code == 'NOT_ASSIGNED') return const [];
      rethrow;
    }
  }
}
