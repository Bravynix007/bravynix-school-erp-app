import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/section_options.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/domain/teaching_assignment.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/domain/teaching_assignments_repository.dart';
import 'package:equatable/equatable.dart';

sealed class StaffTeachingEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the section, and Try again after a failure.
final class StaffTeachingStarted extends StaffTeachingEvent {
  const new();
}

/// Another academic year: what they teach in it is read.
final class StaffTeachingYearChosen extends StaffTeachingEvent {
  const new(this.yearId);

  final String yearId;

  @override
  List<Object?> get props => [yearId];
}

final class StaffTeachingSectionChosen extends StaffTeachingEvent {
  const new(this.sectionId);

  final String? sectionId;

  @override
  List<Object?> get props => [sectionId];
}

final class StaffTeachingSubjectChosen extends StaffTeachingEvent {
  const new(this.subjectId);

  final String? subjectId;

  @override
  List<Object?> get props => [subjectId];
}

/// Assign them the subject in the section, for the year being looked at.
final class StaffTeachingAdded extends StaffTeachingEvent {
  const new();
}

/// End one of the assignments they hold.
final class StaffTeachingEnded extends StaffTeachingEvent {
  const new(this.assignmentId);

  final String assignmentId;

  @override
  List<Object?> get props => [assignmentId];
}

/// The subjects on the staff member's list were saved: the ones that can be assigned are those.
final class StaffTeachingSubjectsChanged extends StaffTeachingEvent {
  const new(this.subjectIds);

  final List<String> subjectIds;

  @override
  List<Object?> get props => [subjectIds];
}

sealed class StaffTeachingState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class StaffTeachingLoading extends StaffTeachingState {
  const new();
}

class StaffTeachingFailed extends StaffTeachingState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// An assignment that was made or ended, for the screen to say so.
class StaffTeachingChange extends Equatable {
  const new(this.assignment, {required this.ended});

  final TeachingAssignment assignment;

  /// True when it was ended, false when it was made.
  final bool ended;

  @override
  List<Object?> get props => [assignment, ended];
}

/// The years, the sections, the subjects they can teach, and what they teach in the [yearId]; with what is chosen for
/// the next assignment.
class StaffTeachingReady extends StaffTeachingState {
  const new({
    required this.years,
    required this.sections,
    required this.subjects,
    required this.yearId,
    required this.assignments,
    this.sectionId,
    this.subjectId,
    this.reading = false,
    this.adding = false,
    this.ending,
    this.failure,
    this.done,
  });

  final List<AcademicYear> years;
  final List<SectionChoice> sections;

  /// The subjects on their own list that are still offered; only these can be assigned (API design 10.5a).
  final List<Subject> subjects;

  /// The year being looked at; null when the Institution has none.
  final String? yearId;

  /// What they teach in the year.
  final List<TeachingAssignment> assignments;
  final String? sectionId;
  final String? subjectId;

  /// The assignments of another year are on their way.
  final bool reading;

  /// An assignment is on its way to be made.
  final bool adding;

  /// The ID of the assignment that is on its way to be ended.
  final String? ending;

  /// The last assignment or end that was refused.
  final ApiFailure? failure;

  /// The last assignment that was made or ended.
  final StaffTeachingChange? done;

  bool get busy => reading || adding || ending != null;

  bool get canAdd => yearId != null && sectionId != null && subjectId != null && !busy;

  StaffTeachingReady copyWith({
    String? Function()? yearId,
    List<Subject>? subjects,
    List<TeachingAssignment>? assignments,
    String? Function()? sectionId,
    String? Function()? subjectId,
    bool? reading,
    bool? adding,
    String? Function()? ending,
    ApiFailure? Function()? failure,
    StaffTeachingChange? Function()? done,
  }) => StaffTeachingReady(
    years: years,
    sections: sections,
    subjects: subjects ?? this.subjects,
    yearId: yearId == null ? this.yearId : yearId(),
    assignments: assignments ?? this.assignments,
    sectionId: sectionId == null ? this.sectionId : sectionId(),
    subjectId: subjectId == null ? this.subjectId : subjectId(),
    reading: reading ?? this.reading,
    adding: adding ?? this.adding,
    ending: ending == null ? this.ending : ending(),
    failure: failure == null ? this.failure : failure(),
    done: done == null ? this.done : done(),
  );

  @override
  List<Object?> get props => [
    years,
    sections,
    subjects,
    yearId,
    assignments,
    sectionId,
    subjectId,
    reading,
    adding,
    ending,
    failure,
    done,
  ];
}

/// What a staff member teaches (ASG-01 to ASG-03): the sections and subjects they hold in an academic year of their
/// home Institution, from the subjects on their own list, with a way to give them one more or to end one.
class StaffTeachingBloc extends Bloc<StaffTeachingEvent, StaffTeachingState> {
  new(this._assignments, this._options, this._subjects, {required this.member}) : super(const StaffTeachingLoading()) {
    on<StaffTeachingStarted>(_onStarted);
    on<StaffTeachingYearChosen>(_onYearChosen);
    on<StaffTeachingSectionChosen>(
      (event, emit) => _ready((ready) => emit(ready.copyWith(sectionId: () => event.sectionId, failure: () => null))),
    );
    on<StaffTeachingSubjectChosen>(
      (event, emit) => _ready((ready) => emit(ready.copyWith(subjectId: () => event.subjectId, failure: () => null))),
    );
    on<StaffTeachingSubjectsChanged>(_onSubjectsChanged);
    on<StaffTeachingAdded>(_onAdded);
    on<StaffTeachingEnded>(_onEnded);
  }

  final TeachingAssignmentsRepository _assignments;
  final SectionOptionsSource _options;
  final SubjectsRepository _subjects;

  /// The staff member as the section was opened.
  final StaffMember member;

  /// The subjects on their list now: those of [member] until a change of them is told.
  late List<String> _subjectIds = member.subjectIds;

  /// The subjects of the Society, as read; the ones on their list are offered from them.
  List<Subject> _catalogue = const [];

  List<Subject> get _offered => [
    for (final subject in _catalogue)
      if (_subjectIds.contains(subject.id)) subject,
  ];

  void _ready(void Function(StaffTeachingReady ready) work) {
    if (state case final StaffTeachingReady ready) work(ready);
  }

  /// All they teach in the year: the list is read a page at a time.
  Future<List<TeachingAssignment>> _read(String yearId) async {
    final all = <TeachingAssignment>[];
    for (var page = 1; ; page++) {
      final read = await _assignments.assignments(
        member.homeInstitutionId,
        academicYearId: yearId,
        staffMemberId: member.id,
        page: page,
      );
      all.addAll(read.items);
      if (!read.hasMore) return all;
    }
  }

  Future<void> _onStarted(StaffTeachingStarted event, Emitter<StaffTeachingState> emit) async {
    emit(const StaffTeachingLoading());
    try {
      final options = await _options.read(member.homeInstitutionId);
      _catalogue = await _subjects.subjects();
      final yearId = options.firstYearId;
      emit(
        StaffTeachingReady(
          years: options.years,
          sections: options.sections,
          subjects: _offered,
          yearId: yearId,
          assignments: yearId == null ? const [] : await _read(yearId),
        ),
      );
    } on ApiFailure catch (failure) {
      emit(StaffTeachingFailed(failure));
    }
  }

  /// The offered subjects follow what was saved; what is in the middle of being chosen stays unless it is no longer offered,
  /// and an assignment on its way is left alone.
  void _onSubjectsChanged(StaffTeachingSubjectsChanged event, Emitter<StaffTeachingState> emit) {
    _subjectIds = event.subjectIds;
    _ready((ready) {
      final offered = _offered;
      emit(
        ready.copyWith(
          subjects: offered,
          subjectId: offered.any((subject) => subject.id == ready.subjectId) ? null : () => null,
        ),
      );
    });
  }

  Future<void> _onYearChosen(StaffTeachingYearChosen event, Emitter<StaffTeachingState> emit) async {
    if (state case final StaffTeachingReady ready when !ready.busy && ready.yearId != event.yearId) {
      emit(
        ready.copyWith(
          yearId: () => event.yearId,
          assignments: const [],
          reading: true,
          failure: () => null,
          done: () => null,
        ),
      );
      try {
        final assignments = await _read(event.yearId);
        _ready((now) => emit(now.copyWith(assignments: assignments, reading: false)));
      } on ApiFailure catch (failure) {
        emit(StaffTeachingFailed(failure));
      }
    }
  }

  Future<void> _onAdded(StaffTeachingAdded event, Emitter<StaffTeachingState> emit) async {
    if (state case final StaffTeachingReady ready when ready.canAdd) {
      emit(ready.copyWith(adding: true, failure: () => null, done: () => null));
      try {
        final made = await _assignments.assign(
          staffMemberId: member.id,
          academicYearId: ready.yearId!,
          sectionId: ready.sectionId!,
          subjectId: ready.subjectId!,
        );
        _ready(
          (now) => emit(
            now.copyWith(
              assignments: [...now.assignments, made],
              sectionId: () => null,
              subjectId: () => null,
              adding: false,
              done: () => StaffTeachingChange(made, ended: false),
            ),
          ),
        );
      } on ApiFailure catch (failure) {
        _ready((now) => emit(now.copyWith(adding: false, failure: () => failure)));
      }
    }
  }

  Future<void> _onEnded(StaffTeachingEnded event, Emitter<StaffTeachingState> emit) async {
    if (state case final StaffTeachingReady ready when !ready.busy) {
      final ended = ready.assignments.where((item) => item.id == event.assignmentId).firstOrNull;
      if (ended == null) return;
      emit(ready.copyWith(ending: () => ended.id, failure: () => null, done: () => null));
      try {
        await _assignments.end(ended.id);
        _ready(
          (now) => emit(
            now.copyWith(
              assignments: _without(now.assignments, ended.id),
              ending: () => null,
              done: () => StaffTeachingChange(ended, ended: true),
            ),
          ),
        );
      } on ApiFailure catch (failure) {
        _ready(
          (now) => emit(
            now.copyWith(
              // Not found is the truth: it is already ended, or gone.
              assignments: failure.code == 'NOT_FOUND' ? _without(now.assignments, ended.id) : null,
              ending: () => null,
              failure: () => failure,
            ),
          ),
        );
      }
    }
  }

  static List<TeachingAssignment> _without(List<TeachingAssignment> items, String id) => [
    for (final item in items)
      if (item.id != id) item,
  ];
}
