import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/classes/domain/class_catalogue.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:equatable/equatable.dart';

sealed class ClassBulkEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Reads what can be added, and again on Try again.
final class ClassBulkStarted extends ClassBulkEvent {
  const new();
}

/// The predefined classes ticked, in the order the list shows them.
final class ClassBulkSubmitted extends ClassBulkEvent {
  const new(this.predefinedClassIds);

  final List<String> predefinedClassIds;

  @override
  List<Object?> get props => [predefinedClassIds];
}

sealed class ClassBulkState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class ClassBulkLoading extends ClassBulkState {
  const new();
}

class ClassBulkFailed extends ClassBulkState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The list is open. [choices] are the predefined classes that can be added in one go: those without a stream, since
/// a Pre-University class needs its stream named and is added one at a time. [failure] is why the last save was
/// refused, and [sent] the predefined classes that save sent, in order, so a refusal naming `classes[1]` can name the
/// class.
class ClassBulkEditing extends ClassBulkState {
  const new({required this.choices, this.saving = false, this.failure, this.sent = const []});

  final List<ClassChoice> choices;
  final bool saving;
  final ApiFailure? failure;
  final List<String> sent;

  @override
  List<Object?> get props => [choices, saving, failure, sent];
}

class ClassBulkSaved extends ClassBulkState {
  const new(this.classes);

  final List<SchoolClass> classes;

  @override
  List<Object?> get props => [classes];
}

/// Adds several classes at once (CLS-03): all of them or none.
class ClassBulkBloc extends Bloc<ClassBulkEvent, ClassBulkState> {
  new(this._classes, this._catalogue, this.institutionId) : super(const ClassBulkLoading()) {
    on<ClassBulkStarted>(_onStarted);
    on<ClassBulkSubmitted>(_onSubmitted);
  }

  final ClassesRepository _classes;
  final ClassCatalogue _catalogue;
  final String institutionId;

  Future<void> _onStarted(ClassBulkStarted event, Emitter<ClassBulkState> emit) async {
    emit(const ClassBulkLoading());
    try {
      final choices = await _catalogue.offered(institutionId);
      emit(
        ClassBulkEditing(
          choices: [
            for (final choice in choices)
              if (!choice.allowsStream) choice,
          ],
        ),
      );
    } on ApiFailure catch (failure) {
      emit(ClassBulkFailed(failure));
    }
  }

  Future<void> _onSubmitted(ClassBulkSubmitted event, Emitter<ClassBulkState> emit) async {
    if (state case final ClassBulkEditing editing when !editing.saving && event.predefinedClassIds.isNotEmpty) {
      emit(ClassBulkEditing(choices: editing.choices, saving: true));
      try {
        emit(
          ClassBulkSaved(
            await _classes.createMany(institutionId, [
              for (final id in event.predefinedClassIds) NewClass(predefinedClassId: id),
            ]),
          ),
        );
      } on ApiFailure catch (failure) {
        emit(ClassBulkEditing(choices: editing.choices, failure: failure, sent: event.predefinedClassIds));
      }
    }
  }
}
