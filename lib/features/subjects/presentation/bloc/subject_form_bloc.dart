import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:equatable/equatable.dart';

/// What the form holds, as typed.
class SubjectFields extends Equatable {
  const new({required this.name, required this.code});

  final String name;
  final String code;

  @override
  List<Object?> get props => [name, code];
}

sealed class SubjectFormEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

final class SubjectFormSubmitted extends SubjectFormEvent {
  const new(this.fields);

  final SubjectFields fields;

  @override
  List<Object?> get props => [fields];
}

sealed class SubjectFormState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The form is open. [failure] is why the last save was refused.
class SubjectFormEditing extends SubjectFormState {
  const new({this.saving = false, this.failure});

  final bool saving;
  final ApiFailure? failure;

  @override
  List<Object?> get props => [saving, failure];
}

class SubjectFormSaved extends SubjectFormState {
  const new(this.subject);

  final Subject subject;

  @override
  List<Object?> get props => [subject];
}

/// Adds a subject (SUB-02), or, with [existing], changes that subject (SUB-03).
class SubjectFormBloc extends Bloc<SubjectFormEvent, SubjectFormState> {
  new(this._subjects, {this.existing}) : super(const SubjectFormEditing()) {
    on<SubjectFormSubmitted>(_onSubmitted);
  }

  final SubjectsRepository _subjects;
  final Subject? existing;

  Future<void> _onSubmitted(SubjectFormSubmitted event, Emitter<SubjectFormState> emit) async {
    if (state case final SubjectFormEditing editing when !editing.saving) {
      emit(const SubjectFormEditing(saving: true));
      final name = event.fields.name.trim();
      // An empty code is no code: left out on add, cleared on edit.
      final code = event.fields.code.trim().isEmpty ? null : event.fields.code.trim();
      try {
        emit(
          SubjectFormSaved(
            existing == null
                ? await _subjects.create(name: name, code: code)
                : await _subjects.update(existing!, name: name, code: code),
          ),
        );
      } on ApiFailure catch (failure) {
        emit(SubjectFormEditing(failure: failure));
      }
    }
  }
}
