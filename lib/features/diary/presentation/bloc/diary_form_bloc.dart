import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/validation/field_problems.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_repository.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:equatable/equatable.dart';

/// The longest description DIA-02 takes.
const maxDiaryDescription = 2000;

/// What the form holds: the subject is null until chosen.
class DiaryFields extends Equatable {
  const new({required this.subjectId, required this.day, required this.description});

  final String? subjectId;

  /// `YYYY-MM-DD`.
  final String day;
  final String description;

  @override
  List<Object?> get props => [subjectId, day, description];
}

sealed class DiaryFormEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Reads the subjects to choose from; sent again on Try again.
final class DiaryFormStarted extends DiaryFormEvent {
  const new();
}

final class DiaryFormSubmitted extends DiaryFormEvent {
  const new(this.fields);

  final DiaryFields fields;

  @override
  List<Object?> get props => [fields];
}

sealed class DiaryFormState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class DiaryFormLoading extends DiaryFormState {
  const new();
}

class DiaryFormLoadFailed extends DiaryFormState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The form is open. [failure] is why the last save was refused.
class DiaryFormEditing extends DiaryFormState {
  const new(this.subjects, {this.saving = false, this.failure});

  final List<Subject> subjects;
  final bool saving;
  final ApiFailure? failure;

  @override
  List<Object?> get props => [subjects, saving, failure];
}

class DiaryFormSaved extends DiaryFormState {
  const new(this.entry);

  final DiaryEntry entry;

  @override
  List<Object?> get props => [entry];
}

/// Adds an entry to [sectionId]'s diary (DIA-02), or, with [existing], changes that entry (DIA-03). The subjects are the
/// Society's, and a teacher is given only those on their own list (SUB-01); the server decides which of them they may
/// write for in the section.
class DiaryFormBloc extends Bloc<DiaryFormEvent, DiaryFormState> {
  new(this._diary, this._subjects, {required this.sectionId, this.existing}) : super(const DiaryFormLoading()) {
    on<DiaryFormStarted>(_onStarted);
    on<DiaryFormSubmitted>(_onSubmitted);
  }

  final DiaryRepository _diary;
  final SubjectsRepository _subjects;
  final String sectionId;
  final DiaryEntry? existing;

  Future<void> _onStarted(DiaryFormStarted event, Emitter<DiaryFormState> emit) async {
    emit(const DiaryFormLoading());
    try {
      emit(DiaryFormEditing(await _subjects.subjects()));
    } on ApiFailure catch (failure) {
      emit(DiaryFormLoadFailed(failure));
    }
  }

  Future<void> _onSubmitted(DiaryFormSubmitted event, Emitter<DiaryFormState> emit) async {
    if (state case final DiaryFormEditing editing when !editing.saving) {
      final fields = event.fields;
      final problems = FieldProblems()
        ..requireChoice('subjectId', fields.subjectId)
        ..requireText('description', fields.description);
      if (problems.failure case final failure?) {
        emit(DiaryFormEditing(editing.subjects, failure: failure));
        return;
      }
      emit(DiaryFormEditing(editing.subjects, saving: true));
      final input = DiaryInput(
        subjectId: fields.subjectId!,
        day: fields.day,
        description: fields.description.trim(),
      );
      try {
        emit(
          DiaryFormSaved(
            existing == null ? await _diary.add(sectionId, input) : await _diary.change(existing!, input),
          ),
        );
      } on ApiFailure catch (failure) {
        emit(DiaryFormEditing(editing.subjects, failure: failure));
      }
    }
  }
}
