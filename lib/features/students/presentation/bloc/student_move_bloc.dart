import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:equatable/equatable.dart';

sealed class StudentMoveEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the form, and Try again after the sections could not be read.
final class StudentMoveStarted extends StudentMoveEvent {
  const new();
}

/// Another class chosen: the student is put in it for the whole year (STU-12), so a section of it has to be chosen too.
final class StudentMoveClassChosen extends StudentMoveEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class StudentMoveSectionChosen extends StudentMoveEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class StudentMoveDateChosen extends StudentMoveEvent {
  const new(this.day);

  /// `YYYY-MM-DD`, or null for today.
  final String? day;

  @override
  List<Object?> get props => [day];
}

/// Save, with the roll number as typed.
final class StudentMoveSubmitted extends StudentMoveEvent {
  const new(this.rollNumber);

  final String rollNumber;

  @override
  List<Object?> get props => [rollNumber];
}

sealed class StudentMoveState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class StudentMoveLoading extends StudentMoveState {
  const new();
}

/// The sections of the student's class could not be read.
class StudentMoveFailed extends StudentMoveState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The classes and sections of the Institution to choose from, and what is chosen.
class StudentMoveReady extends StudentMoveState {
  const new({
    required this.classes,
    required this.sections,
    required this.classId,
    required this.sectionId,
    this.effectiveDate,
    this.saving = false,
    this.failure,
  });

  final List<ClassChoice> classes;
  final List<SectionChoice> sections;
  final String classId;

  /// Null while another class is chosen and none of its sections is yet.
  final String? sectionId;

  /// The first day in the new section; null for today. Only for a section of the class the student is in.
  final String? effectiveDate;
  final bool saving;

  /// The last save that was refused.
  final ApiFailure? failure;

  /// The sections of the chosen class.
  List<SectionChoice> get sectionsInClass => [
    for (final section in sections)
      if (section.classId == classId) section,
  ];

  StudentMoveReady copyWith({
    String? classId,
    String? Function()? sectionId,
    String? Function()? effectiveDate,
    bool? saving,
    ApiFailure? Function()? failure,
  }) => StudentMoveReady(
    classes: classes,
    sections: sections,
    classId: classId ?? this.classId,
    sectionId: sectionId == null ? this.sectionId : sectionId(),
    effectiveDate: effectiveDate == null ? this.effectiveDate : effectiveDate(),
    saving: saving ?? this.saving,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [classes, sections, classId, sectionId, effectiveDate, saving, failure];
}

/// The move went through; [warnings] are the second looks the server asked for.
class StudentMoveSaved extends StudentMoveState {
  const new(this.warnings);

  final List<String> warnings;

  @override
  List<Object?> get props => [warnings];
}

/// Moves a student to another section of their class, or gives them another roll number, from a day (STU-08), or puts
/// them in another class for the whole year when they were in the wrong one (STU-12). Only what changed is sent; the
/// year stays, since the next year is a promotion.
class StudentMoveBloc extends Bloc<StudentMoveEvent, StudentMoveState> {
  new(this._students, this._options, this.student) : super(const StudentMoveLoading()) {
    on<StudentMoveStarted>(_onStarted);
    on<StudentMoveClassChosen>(
      (event, emit) => _ready((ready) {
        final id = event.id;
        if (ready.saving || id == null || id == ready.classId) return;
        // Back in the class they are in, the section they are in is chosen again; in another, none yet, and no day,
        // because the class is corrected for the whole year.
        final here = id == student.placement.classId;
        emit(
          ready.copyWith(
            classId: id,
            sectionId: () => here ? student.placement.sectionId : null,
            effectiveDate: () => null,
            failure: () => null,
          ),
        );
      }),
    );
    on<StudentMoveSectionChosen>(
      (event, emit) => _ready((ready) {
        final id = event.id;
        if (!ready.saving && id != null) emit(ready.copyWith(sectionId: () => id, failure: () => null));
      }),
    );
    on<StudentMoveDateChosen>(
      (event, emit) => _ready((ready) {
        if (!ready.saving) emit(ready.copyWith(effectiveDate: () => event.day, failure: () => null));
      }),
    );
    on<StudentMoveSubmitted>(_onSubmitted);
  }

  final StudentsRepository _students;
  final SectionOptionsSource _options;

  /// The student as the list showed them: where they sit now.
  final StudentSummary student;

  void _ready(void Function(StudentMoveReady ready) work) {
    if (state case final StudentMoveReady ready) work(ready);
  }

  Future<void> _onStarted(StudentMoveStarted event, Emitter<StudentMoveState> emit) async {
    emit(const StudentMoveLoading());
    try {
      final options = await _options.read(student.institutionId);
      emit(
        StudentMoveReady(
          classes: options.classes,
          sections: options.sections,
          classId: student.placement.classId,
          sectionId: student.placement.sectionId,
        ),
      );
    } on ApiFailure catch (failure) {
      emit(StudentMoveFailed(failure));
    }
  }

  Future<void> _onSubmitted(StudentMoveSubmitted event, Emitter<StudentMoveState> emit) async {
    if (state case final StudentMoveReady ready when !ready.saving && ready.sectionId != null) {
      final placement = student.placement;
      final sectionId = ready.sectionId!;
      final rollNumber = event.rollNumber.trim();
      emit(ready.copyWith(saving: true, failure: () => null));
      try {
        final warnings = ready.classId == placement.classId
            ? await _students.move(
                student.id,
                sectionId: sectionId == placement.sectionId ? null : sectionId,
                rollNumber: rollNumber == placement.rollNumber ? null : rollNumber,
                effectiveDate: ready.effectiveDate,
              )
            : await _students.correctClass(
                student.id,
                classId: ready.classId,
                sectionId: sectionId,
                rollNumber: rollNumber == placement.rollNumber ? null : rollNumber,
              );
        emit(StudentMoveSaved(warnings));
      } on ApiFailure catch (failure) {
        _ready((now) => emit(now.copyWith(saving: false, failure: () => failure)));
      }
    }
  }
}
