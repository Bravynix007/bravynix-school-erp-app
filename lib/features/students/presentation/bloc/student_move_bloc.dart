import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
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

/// The sections of the student's class to choose from, and what is chosen.
class StudentMoveReady extends StudentMoveState {
  const new({
    required this.sections,
    required this.sectionId,
    this.effectiveDate,
    this.saving = false,
    this.failure,
  });

  final List<SectionChoice> sections;
  final String sectionId;

  /// The first day in the new section; null for today.
  final String? effectiveDate;
  final bool saving;

  /// The last save that was refused.
  final ApiFailure? failure;

  StudentMoveReady copyWith({
    String? sectionId,
    String? Function()? effectiveDate,
    bool? saving,
    ApiFailure? Function()? failure,
  }) => StudentMoveReady(
    sections: sections,
    sectionId: sectionId ?? this.sectionId,
    effectiveDate: effectiveDate == null ? this.effectiveDate : effectiveDate(),
    saving: saving ?? this.saving,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [sections, sectionId, effectiveDate, saving, failure];
}

/// The move went through; [warnings] are the second looks the server asked for.
class StudentMoveSaved extends StudentMoveState {
  const new(this.warnings);

  final List<String> warnings;

  @override
  List<Object?> get props => [warnings];
}

/// Moves a student to another section of their class, or gives them another roll number, from a day (STU-08). Only
/// what changed is sent; the class and the year stay, since another class is a promotion.
class StudentMoveBloc extends Bloc<StudentMoveEvent, StudentMoveState> {
  new(this._students, this._sections, this.student) : super(const StudentMoveLoading()) {
    on<StudentMoveStarted>(_onStarted);
    on<StudentMoveSectionChosen>(
      (event, emit) => _ready((ready) {
        final id = event.id;
        if (!ready.saving && id != null) emit(ready.copyWith(sectionId: id, failure: () => null));
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
  final SectionsRepository _sections;

  /// The student as the list showed them: where they sit now.
  final StudentSummary student;

  void _ready(void Function(StudentMoveReady ready) work) {
    if (state case final StudentMoveReady ready) work(ready);
  }

  Future<void> _onStarted(StudentMoveStarted event, Emitter<StudentMoveState> emit) async {
    emit(const StudentMoveLoading());
    try {
      final classId = student.placement.classId;
      final sections = await _sections.sections(classId);
      emit(
        StudentMoveReady(
          sections: [
            for (final section in sections) SectionChoice(id: section.id, name: section.displayName, classId: classId),
          ],
          sectionId: student.placement.sectionId,
        ),
      );
    } on ApiFailure catch (failure) {
      emit(StudentMoveFailed(failure));
    }
  }

  Future<void> _onSubmitted(StudentMoveSubmitted event, Emitter<StudentMoveState> emit) async {
    if (state case final StudentMoveReady ready when !ready.saving) {
      final placement = student.placement;
      final rollNumber = event.rollNumber.trim();
      emit(ready.copyWith(saving: true, failure: () => null));
      try {
        final warnings = await _students.move(
          student.id,
          sectionId: ready.sectionId == placement.sectionId ? null : ready.sectionId,
          rollNumber: rollNumber == placement.rollNumber ? null : rollNumber,
          effectiveDate: ready.effectiveDate,
        );
        emit(StudentMoveSaved(warnings));
      } on ApiFailure catch (failure) {
        _ready((now) => emit(now.copyWith(saving: false, failure: () => failure)));
      }
    }
  }
}
