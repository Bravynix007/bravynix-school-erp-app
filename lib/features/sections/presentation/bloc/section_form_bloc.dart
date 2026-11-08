import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:equatable/equatable.dart';

/// What the form holds. [predefinedSectionId] is the section picked to add; it is null when editing, where the
/// predefined section never changes. [capacity] is null when left empty (no capacity).
class SectionFields extends Equatable {
  const new({required this.displayName, this.predefinedSectionId, this.capacity});

  final String? predefinedSectionId;
  final String displayName;
  final int? capacity;

  @override
  List<Object?> get props => [predefinedSectionId, displayName, capacity];
}

sealed class SectionFormEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Reads the predefined sections that can be added, and again on Try again.
final class SectionFormStarted extends SectionFormEvent {
  const new();
}

final class SectionFormSubmitted extends SectionFormEvent {
  const new(this.fields);

  final SectionFields fields;

  @override
  List<Object?> get props => [fields];
}

sealed class SectionFormState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class SectionFormLoading extends SectionFormState {
  const new();
}

class SectionFormFailed extends SectionFormState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The form is open. [choices] are the predefined sections the class does not have yet (none when editing); [failure]
/// is why the last save was refused.
class SectionFormEditing extends SectionFormState {
  const new({this.choices = const [], this.saving = false, this.failure});

  final List<MasterEntry> choices;
  final bool saving;
  final ApiFailure? failure;

  @override
  List<Object?> get props => [choices, saving, failure];
}

class SectionFormSaved extends SectionFormState {
  const new(this.section);

  final Section section;

  @override
  List<Object?> get props => [section];
}

/// Adds a section (SEC-02) to [classId], or, with [existing], changes that section's name and capacity (SEC-03).
class SectionFormBloc extends Bloc<SectionFormEvent, SectionFormState> {
  new(this._sections, this._masters, this.classId, {this.taken = const {}, this.existing})
    : super(existing == null ? const SectionFormLoading() : const SectionFormEditing()) {
    on<SectionFormStarted>(_onStarted);
    on<SectionFormSubmitted>(_onSubmitted);
  }

  final SectionsRepository _sections;
  final MastersRepository _masters;
  final String classId;

  /// The predefined sections the class has already; a class cannot have one twice.
  final Set<String> taken;
  final Section? existing;

  Future<void> _onStarted(SectionFormStarted event, Emitter<SectionFormState> emit) async {
    if (existing != null) return;
    emit(const SectionFormLoading());
    try {
      final entries = await _masters.entries(MasterType.predefinedSections);
      emit(
        SectionFormEditing(
          choices: [
            for (final entry in entries)
              if (!taken.contains(entry.id)) entry,
          ],
        ),
      );
    } on ApiFailure catch (failure) {
      emit(SectionFormFailed(failure));
    }
  }

  Future<void> _onSubmitted(SectionFormSubmitted event, Emitter<SectionFormState> emit) async {
    if (state case final SectionFormEditing editing when !editing.saving) {
      emit(SectionFormEditing(choices: editing.choices, saving: true));
      final fields = event.fields;
      final name = fields.displayName.trim();
      try {
        final saved = existing == null
            ? await _sections.create(
                classId,
                predefinedSectionId: fields.predefinedSectionId!,
                displayName: name.isEmpty ? null : name,
                capacity: fields.capacity,
              )
            : await _sections.update(existing!, displayName: name, capacity: fields.capacity);
        emit(SectionFormSaved(saved));
      } on ApiFailure catch (failure) {
        emit(SectionFormEditing(choices: editing.choices, failure: failure));
      }
    }
  }
}
