import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/classes/domain/class_catalogue.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:equatable/equatable.dart';

/// What the form holds, as typed. [choice] is the predefined class picked to add; it is null when editing, where the
/// predefined class never changes.
class ClassFields extends Equatable {
  const new({required this.displayName, required this.code, required this.streamName, this.choice});

  final ClassChoice? choice;
  final String streamName;
  final String displayName;
  final String code;

  @override
  List<Object?> get props => [choice, streamName, displayName, code];
}

sealed class ClassFormEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Reads what can be added, and again on Try again.
final class ClassFormStarted extends ClassFormEvent {
  const new();
}

final class ClassFormSubmitted extends ClassFormEvent {
  const new(this.fields);

  final ClassFields fields;

  @override
  List<Object?> get props => [fields];
}

sealed class ClassFormState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class ClassFormLoading extends ClassFormState {
  const new();
}

/// What can be added could not be read.
class ClassFormFailed extends ClassFormState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The form is open. [choices] are the predefined classes that can be added (none when editing); [failure] is why the
/// last save was refused.
class ClassFormEditing extends ClassFormState {
  const new({this.choices = const [], this.saving = false, this.failure});

  final List<ClassChoice> choices;
  final bool saving;
  final ApiFailure? failure;

  @override
  List<Object?> get props => [choices, saving, failure];
}

class ClassFormSaved extends ClassFormState {
  const new(this.schoolClass);

  final SchoolClass schoolClass;

  @override
  List<Object?> get props => [schoolClass];
}

/// Adds a class (CLS-02) to [institutionId], or, with [existing], changes that class's name and code (CLS-04).
class ClassFormBloc extends Bloc<ClassFormEvent, ClassFormState> {
  new(this._classes, this._catalogue, this.institutionId, {this.existing})
    : super(existing == null ? const ClassFormLoading() : const ClassFormEditing()) {
    on<ClassFormStarted>(_onStarted);
    on<ClassFormSubmitted>(_onSubmitted);
  }

  final ClassesRepository _classes;
  final ClassCatalogue _catalogue;
  final String institutionId;
  final SchoolClass? existing;

  Future<void> _onStarted(ClassFormStarted event, Emitter<ClassFormState> emit) async {
    if (existing != null) return;
    emit(const ClassFormLoading());
    try {
      emit(ClassFormEditing(choices: await _catalogue.offered(institutionId)));
    } on ApiFailure catch (failure) {
      emit(ClassFormFailed(failure));
    }
  }

  static String? _orNull(String text) => text.trim().isEmpty ? null : text.trim();

  Future<void> _onSubmitted(ClassFormSubmitted event, Emitter<ClassFormState> emit) async {
    if (state case final ClassFormEditing editing when !editing.saving) {
      emit(ClassFormEditing(choices: editing.choices, saving: true));
      final fields = event.fields;
      try {
        final saved = existing == null
            ? await _classes.create(
                institutionId,
                NewClass(
                  predefinedClassId: fields.choice!.predefinedClass.id,
                  streamName: fields.choice!.allowsStream ? _orNull(fields.streamName) : null,
                ),
                displayName: _orNull(fields.displayName),
                code: _orNull(fields.code),
              )
            : await _classes.update(existing!, displayName: fields.displayName.trim(), code: _orNull(fields.code));
        emit(ClassFormSaved(saved));
      } on ApiFailure catch (failure) {
        emit(ClassFormEditing(choices: editing.choices, failure: failure));
      }
    }
  }
}
