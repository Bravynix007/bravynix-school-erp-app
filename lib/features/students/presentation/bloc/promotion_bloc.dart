import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/promotion.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Who is promoted: one student from where they sit (STU-09), or the students of a class or section chosen on the form
/// (PRM-01).
sealed class PromotionScope extends Equatable {
  const new();

  String get institutionId;
}

final class PromoteOne extends PromotionScope {
  const new(this.student);

  final StudentSummary student;

  @override
  String get institutionId => student.institutionId;

  @override
  List<Object?> get props => [student];
}

final class PromoteGroup extends PromotionScope {
  const new(this.institutionId);

  @override
  final String institutionId;

  @override
  List<Object?> get props => [institutionId];
}

sealed class PromotionEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the form, and Try again after the years and sections could not be read.
final class PromotionStarted extends PromotionEvent {
  const new();
}

/// The year the students are in now, for a class or section.
final class PromotionSourceYearChosen extends PromotionEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class PromotionSourceClassChosen extends PromotionEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

/// One section of the class, or every section of it when null.
final class PromotionSourceSectionChosen extends PromotionEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class PromotionTargetYearChosen extends PromotionEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

/// Another class: no section of it is chosen yet.
final class PromotionTargetClassChosen extends PromotionEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class PromotionTargetSectionChosen extends PromotionEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

/// Completing the final class instead of going to a class of the next year.
final class PromotionCompletesToggled extends PromotionEvent {
  const new({required this.value});

  final bool value;

  @override
  List<Object?> get props => [value];
}

/// Keep the roll numbers, or number the students again in the new section.
final class PromotionKeepRollNumbersToggled extends PromotionEvent {
  const new({required this.value});

  final bool value;

  @override
  List<Object?> get props => [value];
}

/// Promote. [rollNumber] is the one typed for a single student, empty to keep theirs.
final class PromotionSubmitted extends PromotionEvent {
  const new({this.rollNumber = ''});

  final String rollNumber;

  @override
  List<Object?> get props => [rollNumber];
}

sealed class PromotionState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class PromotionLoading extends PromotionState {
  const new();
}

/// The years, classes and sections could not be read.
class PromotionFailed extends PromotionState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The choices of the Institution, and what is chosen.
class PromotionReady extends PromotionState {
  const new({
    required this.years,
    required this.classes,
    required this.sections,
    this.sourceYearId,
    this.sourceClassId,
    this.sourceSectionId,
    this.targetYearId,
    this.targetClassId,
    this.targetSectionId,
    this.completes = false,
    this.keepRollNumbers = true,
    this.saving = false,
    this.failure,
  });

  final List<AcademicYear> years;
  final List<ClassChoice> classes;
  final List<SectionChoice> sections;

  /// Where the students are now. Fixed for one student; chosen for a class.
  final String? sourceYearId;
  final String? sourceClassId;

  /// Null for every section of the class.
  final String? sourceSectionId;
  final String? targetYearId;
  final String? targetClassId;
  final String? targetSectionId;
  final bool completes;
  final bool keepRollNumbers;
  final bool saving;

  /// The last attempt that was refused.
  final ApiFailure? failure;

  List<SectionChoice> get sourceSections => _inClass(sourceClassId);

  List<SectionChoice> get targetSections => _inClass(targetClassId);

  List<SectionChoice> _inClass(String? classId) => [
    for (final section in sections)
      if (section.classId == classId) section,
  ];

  /// The years that begin after the year the students are in, earliest first: all a promotion can go to.
  List<AcademicYear> get targetYears {
    final source = years.where((year) => year.id == sourceYearId).firstOrNull;
    return [
      for (final year in years)
        if (source == null || year.startDate.compareTo(source.startDate) > 0) year,
    ]..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// What the choices make of the target; null when completing, or when a part is not chosen yet.
  PromotionTarget? get target {
    final year = targetYearId;
    final schoolClass = targetClassId;
    final section = targetSectionId;
    if (completes || year == null || schoolClass == null || section == null) return null;
    return PromotionTarget(academicYearId: year, classId: schoolClass, sectionId: section);
  }

  /// The name of the section the students go to, as the done message says it.
  String? get targetName => sections.where((section) => section.id == targetSectionId).firstOrNull?.name;

  bool get canSubmit => !saving && (completes || target != null) && (sourceClassId != null && sourceYearId != null);

  PromotionReady copyWith({
    String? Function()? sourceYearId,
    String? Function()? sourceClassId,
    String? Function()? sourceSectionId,
    String? Function()? targetYearId,
    String? Function()? targetClassId,
    String? Function()? targetSectionId,
    bool? completes,
    bool? keepRollNumbers,
    bool? saving,
    ApiFailure? Function()? failure,
  }) => PromotionReady(
    years: years,
    classes: classes,
    sections: sections,
    sourceYearId: sourceYearId == null ? this.sourceYearId : sourceYearId(),
    sourceClassId: sourceClassId == null ? this.sourceClassId : sourceClassId(),
    sourceSectionId: sourceSectionId == null ? this.sourceSectionId : sourceSectionId(),
    targetYearId: targetYearId == null ? this.targetYearId : targetYearId(),
    targetClassId: targetClassId == null ? this.targetClassId : targetClassId(),
    targetSectionId: targetSectionId == null ? this.targetSectionId : targetSectionId(),
    completes: completes ?? this.completes,
    keepRollNumbers: keepRollNumbers ?? this.keepRollNumbers,
    saving: saving ?? this.saving,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [
    years,
    classes,
    sections,
    sourceYearId,
    sourceClassId,
    sourceSectionId,
    targetYearId,
    targetClassId,
    targetSectionId,
    completes,
    keepRollNumbers,
    saving,
    failure,
  ];
}

/// The promotion went through. [targetName] is the section they went to, null when they completed the final class.
class PromotionDone extends PromotionState {
  const new(this.result, {this.targetName});

  final PromotionResult result;
  final String? targetName;

  @override
  List<Object?> get props => [result, targetName];
}

/// Promotes one student (STU-09), or the students of a class or section (PRM-01), to a class of a later year, or lets
/// them complete the final class. A repeat of the same class attempt, after an answer that was lost, carries the same
/// Idempotency-Key, so it finds the first one done.
class PromotionBloc extends Bloc<PromotionEvent, PromotionState> {
  new(this._students, this._options, this.scope, {String Function()? newKey})
    : _newKey = newKey ?? const Uuid().v4,
      super(const PromotionLoading()) {
    on<PromotionStarted>(_onStarted);
    on<PromotionSourceYearChosen>(
      (event, emit) => _change(emit, event.id, (ready, id) => _aimed(ready.copyWith(sourceYearId: () => id))),
    );
    on<PromotionSourceClassChosen>(
      (event, emit) => _change(
        emit,
        event.id,
        (ready, id) => _aimed(ready.copyWith(sourceClassId: () => id, sourceSectionId: () => null)),
      ),
    );
    on<PromotionSourceSectionChosen>(
      (event, emit) =>
          _change(emit, event.id, (ready, id) => ready.copyWith(sourceSectionId: () => id), nullable: true),
    );
    on<PromotionTargetYearChosen>(
      (event, emit) => _change(emit, event.id, (ready, id) => ready.copyWith(targetYearId: () => id)),
    );
    on<PromotionTargetClassChosen>(
      (event, emit) => _change(
        emit,
        event.id,
        (ready, id) => ready.copyWith(targetClassId: () => id, targetSectionId: () => null),
      ),
    );
    on<PromotionTargetSectionChosen>(
      (event, emit) => _change(emit, event.id, (ready, id) => ready.copyWith(targetSectionId: () => id)),
    );
    on<PromotionCompletesToggled>(
      (event, emit) => _change(emit, event.value, (ready, value) => ready.copyWith(completes: value)),
    );
    on<PromotionKeepRollNumbersToggled>(
      (event, emit) => _change(emit, event.value, (ready, value) => ready.copyWith(keepRollNumbers: value)),
    );
    on<PromotionSubmitted>(_onSubmitted);
  }

  final StudentsRepository _students;
  final SectionOptionsSource _options;
  final PromotionScope scope;
  final String Function() _newKey;

  /// The key of the class attempt that is on its way or was refused, kept so a repeat of it is the same attempt; null
  /// once anything it would send changes.
  String? _key;

  /// A choice changed by the person: it is made when nothing is on its way, and the attempt is a new one.
  void _change<T>(
    Emitter<PromotionState> emit,
    T value,
    PromotionReady Function(PromotionReady ready, T value) apply, {
    bool nullable = false,
  }) {
    if (state case final PromotionReady ready when !ready.saving && (nullable || value != null)) {
      _key = null;
      emit(apply(ready, value).copyWith(failure: () => null));
    }
  }

  /// The target the source calls for: the next year, and the next class (the same when it is the last).
  PromotionReady _aimed(PromotionReady ready) {
    final index = ready.classes.indexWhere((choice) => choice.id == ready.sourceClassId);
    final next = index < 0 ? null : ready.classes[index + 1 < ready.classes.length ? index + 1 : index];
    return ready.copyWith(
      targetYearId: () => ready.targetYears.firstOrNull?.id,
      targetClassId: () => next?.id,
      targetSectionId: () => null,
    );
  }

  Future<void> _onStarted(PromotionStarted event, Emitter<PromotionState> emit) async {
    emit(const PromotionLoading());
    try {
      final options = await _options.read(scope.institutionId);
      final ready = PromotionReady(years: options.years, classes: options.classes, sections: options.sections);
      emit(switch (scope) {
        PromoteOne(:final student) => _aimed(
          ready.copyWith(
            sourceYearId: () => student.placement.academicYearId,
            sourceClassId: () => student.placement.classId,
            sourceSectionId: () => student.placement.sectionId,
          ),
        ),
        PromoteGroup() => _aimed(
          ready.copyWith(sourceYearId: () => options.firstYearId, sourceClassId: () => options.classes.firstOrNull?.id),
        ),
      });
    } on ApiFailure catch (failure) {
      emit(PromotionFailed(failure));
    }
  }

  Future<void> _onSubmitted(PromotionSubmitted event, Emitter<PromotionState> emit) async {
    if (state case final PromotionReady ready when ready.canSubmit) {
      emit(ready.copyWith(saving: true, failure: () => null));
      try {
        final result = switch (scope) {
          PromoteOne(:final student) => await _promoteOne(student, ready, event.rollNumber.trim()),
          PromoteGroup(:final institutionId) => await _promoteGroup(institutionId, ready),
        };
        _key = null;
        emit(PromotionDone(result, targetName: ready.completes ? null : ready.targetName));
      } on ApiFailure catch (failure) {
        if (state case final PromotionReady now) emit(now.copyWith(saving: false, failure: () => failure));
      }
    }
  }

  Future<PromotionResult> _promoteOne(StudentSummary student, PromotionReady ready, String rollNumber) async {
    final promoted = await _students.promoteStudent(
      student.id,
      target: ready.target,
      // A roll number belongs to a new place: completing the final class has none.
      rollNumber: ready.completes || rollNumber.isEmpty || rollNumber == student.placement.rollNumber
          ? null
          : rollNumber,
    );
    return PromotionResult(promotedCount: 1, warnings: promoted.warnings);
  }

  Future<PromotionResult> _promoteGroup(String institutionId, PromotionReady ready) {
    return _students.promote(
      institutionId: institutionId,
      fromAcademicYearId: ready.sourceYearId!,
      fromClassId: ready.sourceClassId!,
      fromSectionId: ready.sourceSectionId,
      target: ready.target,
      keepRollNumbers: ready.keepRollNumbers,
      idempotencyKey: _key ??= _newKey(),
    );
  }
}
