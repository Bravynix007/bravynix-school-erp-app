import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:equatable/equatable.dart';

/// The most subjects, and the most extra Institutions, one staff member can hold (STF-08, STF-10).
const maxStaffAccessChoices = 50;

/// The two lists the access tab changes, each saved on its own.
enum StaffAccessPart { subjects, institutions }

sealed class StaffAccessEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the tab, and Try again after a failure.
final class StaffAccessStarted extends StaffAccessEvent {
  const new();
}

final class StaffSubjectToggled extends StaffAccessEvent {
  const new(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class StaffInstitutionToggled extends StaffAccessEvent {
  const new(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class StaffAccessSaved extends StaffAccessEvent {
  const new(this.part);

  final StaffAccessPart part;

  @override
  List<Object?> get props => [part];
}

sealed class StaffAccessState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class StaffAccessLoading extends StaffAccessState {
  const new();
}

class StaffAccessFailed extends StaffAccessState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// What the person may do, and what can be chosen: [subjects] and [institutions] are the lists to choose from, and
/// [subjectIds] and [institutionIds] what is ticked now, which may differ from what the [member] holds until it is saved.
class StaffAccessReady extends StaffAccessState {
  const new({
    required this.member,
    required this.subjects,
    required this.institutions,
    required this.subjectIds,
    required this.institutionIds,
    this.saving,
    this.failure,
    this.failedPart,
  });

  final StaffMember member;
  final List<Subject> subjects;

  /// The Institutions of the Society other than the home one; empty for a caller who cannot change them.
  final List<InstitutionSummary> institutions;
  final List<String> subjectIds;
  final List<String> institutionIds;

  /// The list being saved.
  final StaffAccessPart? saving;

  /// The last save that was refused, and the list it was for.
  final ApiFailure? failure;
  final StaffAccessPart? failedPart;

  bool get canAddSubject => subjectIds.length < maxStaffAccessChoices;
  bool get canAddInstitution => institutionIds.length < maxStaffAccessChoices;

  static bool _same(List<String> a, List<String> b) => a.length == b.length && a.toSet().containsAll(b);

  bool changed(StaffAccessPart part) => switch (part) {
    StaffAccessPart.subjects => !_same(subjectIds, member.subjectIds),
    StaffAccessPart.institutions => !_same(institutionIds, member.institutionIds),
  };

  StaffAccessReady copyWith({
    StaffMember? member,
    List<String>? subjectIds,
    List<String>? institutionIds,
    StaffAccessPart? Function()? saving,
    ApiFailure? Function()? failure,
    StaffAccessPart? Function()? failedPart,
  }) => StaffAccessReady(
    member: member ?? this.member,
    subjects: subjects,
    institutions: institutions,
    subjectIds: subjectIds ?? this.subjectIds,
    institutionIds: institutionIds ?? this.institutionIds,
    saving: saving == null ? this.saving : saving(),
    failure: failure == null ? this.failure : failure(),
    failedPart: failedPart == null ? this.failedPart : failedPart(),
  );

  @override
  List<Object?> get props => [member, subjects, institutions, subjectIds, institutionIds, saving, failure, failedPart];
}

/// The access tab of one staff member: the subjects they can teach (STF-08) and, for the Society Owner, the extra
/// Institutions they may see (STF-10). [canChangeInstitutions] is false for an Institution Admin, who does not read the
/// Institutions either.
class StaffAccessBloc extends Bloc<StaffAccessEvent, StaffAccessState> {
  new(this._staff, this._subjects, this._institutions, {required this.member, required this.canChangeInstitutions})
    : super(const StaffAccessLoading()) {
    on<StaffAccessStarted>(_onStarted);
    on<StaffSubjectToggled>(
      (event, emit) => _ready((ready) {
        // A list on its way to the API is left as it is: the answer would undo a tick made meanwhile.
        if (ready.saving == StaffAccessPart.subjects) return;
        emit(
          ready.copyWith(
            subjectIds: _toggled(ready.subjectIds, event.id, allowAdd: ready.canAddSubject),
            // The refusal stays under a list that is still the refused one.
            failure: ready.failedPart == StaffAccessPart.subjects ? () => null : null,
            failedPart: ready.failedPart == StaffAccessPart.subjects ? () => null : null,
          ),
        );
      }),
    );
    on<StaffInstitutionToggled>(
      (event, emit) => _ready((ready) {
        if (ready.saving == StaffAccessPart.institutions) return;
        emit(
          ready.copyWith(
            institutionIds: _toggled(ready.institutionIds, event.id, allowAdd: ready.canAddInstitution),
            failure: ready.failedPart == StaffAccessPart.institutions ? () => null : null,
            failedPart: ready.failedPart == StaffAccessPart.institutions ? () => null : null,
          ),
        );
      }),
    );
    on<StaffAccessSaved>(_onSaved);
  }

  final StaffRepository _staff;
  final SubjectsRepository _subjects;
  final InstitutionsRepository _institutions;

  /// The staff member as the tab was opened.
  final StaffMember member;
  final bool canChangeInstitutions;

  void _ready(void Function(StaffAccessReady ready) work) {
    if (state case final StaffAccessReady ready) work(ready);
  }

  static List<String> _toggled(List<String> ids, String id, {required bool allowAdd}) {
    if (ids.contains(id)) {
      return [
        for (final other in ids)
          if (other != id) other,
      ];
    }
    return allowAdd ? [...ids, id] : ids;
  }

  Future<void> _onStarted(StaffAccessStarted event, Emitter<StaffAccessState> emit) async {
    emit(const StaffAccessLoading());
    try {
      final subjects = await _subjects.subjects();
      final institutions = canChangeInstitutions
          ? [
              for (final institution in await _institutions.institutions())
                if (institution.id != member.homeInstitutionId) institution,
            ]
          : const <InstitutionSummary>[];
      emit(
        StaffAccessReady(
          member: member,
          subjects: subjects,
          institutions: institutions,
          subjectIds: member.subjectIds,
          institutionIds: member.institutionIds,
        ),
      );
    } on ApiFailure catch (failure) {
      emit(StaffAccessFailed(failure));
    }
  }

  Future<void> _onSaved(StaffAccessSaved event, Emitter<StaffAccessState> emit) async {
    if (state case final StaffAccessReady ready when ready.saving == null && ready.changed(event.part)) {
      emit(ready.copyWith(saving: () => event.part, failure: () => null, failedPart: () => null));
      try {
        final saved = switch (event.part) {
          StaffAccessPart.subjects => await _staff.setSubjects(ready.member.id, ready.subjectIds),
          StaffAccessPart.institutions => await _staff.setInstitutions(ready.member.id, ready.institutionIds),
        };
        // The other list keeps what is ticked and not yet saved; this one shows what the API holds now.
        if (state case final StaffAccessReady now) {
          emit(
            now.copyWith(
              member: saved,
              subjectIds: event.part == StaffAccessPart.subjects ? saved.subjectIds : null,
              institutionIds: event.part == StaffAccessPart.institutions ? saved.institutionIds : null,
              saving: () => null,
            ),
          );
        }
      } on ApiFailure catch (failure) {
        if (state case final StaffAccessReady now) {
          emit(now.copyWith(saving: () => null, failure: () => failure, failedPart: () => event.part));
        }
      }
    }
  }
}
