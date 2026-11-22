import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

sealed class AttendanceEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, and Try again after the classes could not be read.
final class AttendanceStarted extends AttendanceEvent {
  const new();
}

/// Another class chosen: its section has to be chosen too, unless it has only one.
final class AttendanceClassChosen extends AttendanceEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class AttendanceSectionChosen extends AttendanceEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

/// Another day, `YYYY-MM-DD`.
final class AttendanceDayChosen extends AttendanceEvent {
  const new(this.day);

  final String day;

  @override
  List<Object?> get props => [day];
}

/// Try again after the roll could not be read.
final class AttendanceRollRetried extends AttendanceEvent {
  const new();
}

/// One student marked.
final class AttendanceMarked extends AttendanceEvent {
  const new(this.enrolmentId, this.mark);

  final String enrolmentId;
  final AttendanceMark mark;

  @override
  List<Object?> get props => [enrolmentId, mark];
}

/// Confirm & Submit Attendance, for a day with no register yet (ATT-02).
final class AttendanceSubmitted extends AttendanceEvent {
  const new();
}

/// Save corrections, for a day whose register is taken (ATT-05).
final class AttendanceCorrected extends AttendanceEvent {
  const new();
}

/// Void the register of the day, for a reason (ATT-06).
final class AttendanceVoided extends AttendanceEvent {
  const new(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

enum AttendanceOutcomeKind { submitted, corrected, voided }

/// What the last action did, for the screen to say once: [count] is the students on the register.
class AttendanceOutcome extends Equatable {
  const new(this.kind, this.count);

  final AttendanceOutcomeKind kind;
  final int count;

  @override
  List<Object?> get props => [kind, count];
}

/// What the screen shows under the filters.
sealed class AttendanceBoard extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// No section is chosen yet.
class BoardEmpty extends AttendanceBoard {
  const new();
}

class BoardLoading extends AttendanceBoard {
  const new();
}

class BoardFailed extends AttendanceBoard {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The roll with the marks as they stand on screen. [saving] is an action on its way; [failure] is why the last one was
/// refused.
class BoardLoaded extends AttendanceBoard {
  const new(this.roster, this.marks, {this.saving = false, this.failure});

  final AttendanceRoster roster;

  /// The mark of every student by enrolment, as the person has set them.
  final Map<String, AttendanceMark> marks;
  final bool saving;
  final ApiFailure? failure;

  AttendanceMark markOf(RosterStudent student) => marks[student.enrolmentId] ?? student.mark;

  /// The students whose mark is not the one the roll came with: what a correction sends.
  List<MarkChange> get changes => [
    for (final student in roster.students)
      if (markOf(student) != student.mark) MarkChange(enrolmentId: student.enrolmentId, mark: markOf(student)),
  ];

  /// The students who are not Present: what a new register sends.
  List<MarkChange> get exceptions => [
    for (final student in roster.students)
      if (markOf(student) != AttendanceMark.present)
        MarkChange(enrolmentId: student.enrolmentId, mark: markOf(student)),
  ];

  /// How many students are Present as the marks stand.
  int get present => roster.students.where((student) => markOf(student) == AttendanceMark.present).length;

  BoardLoaded copyWith({Map<String, AttendanceMark>? marks, bool? saving, ApiFailure? Function()? failure}) =>
      BoardLoaded(
        roster,
        marks ?? this.marks,
        saving: saving ?? this.saving,
        failure: failure == null ? this.failure : failure(),
      );

  @override
  List<Object?> get props => [roster, marks, saving, failure];
}

sealed class AttendanceState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class AttendanceLoading extends AttendanceState {
  const new();
}

/// The classes could not be read.
class AttendanceFailed extends AttendanceState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The classes and sections to choose from, what is chosen, and the roll of it.
class AttendanceReady extends AttendanceState {
  const new({
    required this.classes,
    required this.sections,
    required this.day,
    this.classId,
    this.sectionId,
    this.board = const BoardEmpty(),
    this.outcome,
  });

  final List<ClassChoice> classes;
  final List<SectionChoice> sections;
  final String? classId;
  final String? sectionId;

  /// `YYYY-MM-DD`.
  final String day;
  final AttendanceBoard board;

  /// What the last action did; null after any later change, so the screen says it once.
  final AttendanceOutcome? outcome;

  List<SectionChoice> get sectionsInClass => sections.inClass(classId);

  AttendanceReady copyWith({
    String? Function()? classId,
    String? Function()? sectionId,
    String? day,
    AttendanceBoard? board,
    AttendanceOutcome? outcome,
  }) => AttendanceReady(
    classes: classes,
    sections: sections,
    classId: classId == null ? this.classId : classId(),
    sectionId: sectionId == null ? this.sectionId : sectionId(),
    day: day ?? this.day,
    board: board ?? this.board,
    outcome: outcome,
  );

  @override
  List<Object?> get props => [classes, sections, classId, sectionId, day, board, outcome];
}

/// Taking a section's attendance for a day, correcting it and voiding it (API design 10.10 to 10.12a). A register is one
/// per section and day; everyone is Present until a mark says otherwise, so only the others are sent. A repeat of the
/// same submission, after an answer that was lost, carries the same Idempotency-Key and finds the first one done; any
/// change to the marks or the roll starts a new attempt.
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  new(this._attendance, this.institutionId, {this._clock = DateTime.now, String Function()? newKey})
    : _newKey = newKey ?? const Uuid().v4,
      super(const AttendanceLoading()) {
    on<AttendanceStarted>(_onStarted);
    on<AttendanceClassChosen>(_onClassChosen);
    on<AttendanceSectionChosen>(_onSectionChosen);
    on<AttendanceDayChosen>(_onDayChosen);
    on<AttendanceRollRetried>((event, emit) => _read(emit));
    on<AttendanceMarked>(_onMarked);
    on<AttendanceSubmitted>(_onSubmitted);
    on<AttendanceCorrected>(_onCorrected);
    on<AttendanceVoided>(_onVoided);
  }

  final AttendanceRepository _attendance;
  final String institutionId;
  final DateTime Function() _clock;
  final String Function() _newKey;
  String? _key;

  /// The roll being read, so an answer for a section or day the person has left is not shown.
  int _reading = 0;

  /// Refusals that mean the roll on screen is out of date: the register was taken or voided, or a student joined or
  /// left, since it was read.
  static const _outOfDate = {'ROSTER_CHANGED', 'ATTENDANCE_ALREADY_SUBMITTED', 'VERSION_CONFLICT', 'SESSION_VOIDED'};

  void _ready(void Function(AttendanceReady ready) work) {
    if (state case final AttendanceReady ready) work(ready);
  }

  Future<void> _onStarted(AttendanceStarted event, Emitter<AttendanceState> emit) async {
    emit(const AttendanceLoading());
    try {
      final choices = await _attendance.sections(institutionId);
      final single = choices.classes.length == 1 ? choices.classes.single.id : null;
      emit(
        AttendanceReady(
          classes: choices.classes,
          sections: choices.sections,
          day: Formatters.schoolDay(_clock()),
          classId: single,
        ),
      );
      // A school with one class and one section has nothing to choose.
      if (single != null) _chooseOnlySection();
    } on ApiFailure catch (failure) {
      emit(AttendanceFailed(failure));
    }
  }

  void _chooseOnlySection() => _ready((ready) {
    final only = ready.sectionsInClass;
    if (only.length == 1) add(AttendanceSectionChosen(only.single.id));
  });

  void _onClassChosen(AttendanceClassChosen event, Emitter<AttendanceState> emit) => _ready((ready) {
    final id = event.id;
    if (id == null || id == ready.classId || _busy(ready)) return;
    _reading++;
    emit(ready.copyWith(classId: () => id, sectionId: () => null, board: const BoardEmpty()));
    _chooseOnlySection();
  });

  Future<void> _onSectionChosen(AttendanceSectionChosen event, Emitter<AttendanceState> emit) async {
    if (state case final AttendanceReady ready) {
      final id = event.id;
      if (id == null || id == ready.sectionId || _busy(ready)) return;
      emit(ready.copyWith(sectionId: () => id));
      await _read(emit);
    }
  }

  Future<void> _onDayChosen(AttendanceDayChosen event, Emitter<AttendanceState> emit) async {
    if (state case final AttendanceReady ready) {
      if (event.day == ready.day || _busy(ready)) return;
      emit(ready.copyWith(day: event.day));
      await _read(emit);
    }
  }

  /// No other choice is taken while an action is on its way: its answer belongs to the roll that was on screen.
  bool _busy(AttendanceReady ready) => switch (ready.board) {
    BoardLoaded(:final saving) => saving,
    _ => false,
  };

  /// Reads the roll of the chosen section and day; [failure] is a refusal to show over it (the roll it came from was out
  /// of date), and [outcome] what the last action did.
  Future<void> _read(Emitter<AttendanceState> emit, {ApiFailure? failure, AttendanceOutcome? outcome}) async {
    if (state case final AttendanceReady ready when ready.sectionId != null) {
      final token = ++_reading;
      _key = null;
      emit(ready.copyWith(board: const BoardLoading()));
      AttendanceBoard board;
      try {
        final roster = await _attendance.roster(ready.sectionId!, ready.day);
        board = BoardLoaded(roster, const {}, failure: failure);
      } on ApiFailure catch (failed) {
        board = BoardFailed(failed);
      }
      if (token != _reading) return;
      if (state case final AttendanceReady current) emit(current.copyWith(board: board, outcome: outcome));
    }
  }

  void _onMarked(AttendanceMarked event, Emitter<AttendanceState> emit) => _ready((ready) {
    if (ready.board case final BoardLoaded board when !board.saving) {
      _key = null;
      emit(
        ready.copyWith(
          board: board.copyWith(marks: {...board.marks, event.enrolmentId: event.mark}, failure: () => null),
        ),
      );
    }
  });

  Future<void> _onSubmitted(AttendanceSubmitted event, Emitter<AttendanceState> emit) => _act(
    emit,
    (board) async {
      final counts = await _attendance.submit(
        sectionId: board.roster.sectionId,
        day: board.roster.day,
        rosterCount: board.roster.students.length,
        exceptions: board.exceptions,
        idempotencyKey: _key ??= _newKey(),
      );
      return AttendanceOutcome(AttendanceOutcomeKind.submitted, counts.rosterCount);
    },
  );

  Future<void> _onCorrected(AttendanceCorrected event, Emitter<AttendanceState> emit) => _act(emit, (board) async {
    final counts = await _attendance.correct(board.roster.taken!.id, board.roster.taken!.version, board.changes);
    return AttendanceOutcome(AttendanceOutcomeKind.corrected, counts.rosterCount);
  });

  Future<void> _onVoided(AttendanceVoided event, Emitter<AttendanceState> emit) => _act(emit, (board) async {
    await _attendance.voidRegister(board.roster.taken!.id, board.roster.taken!.version, event.reason);
    return AttendanceOutcome(AttendanceOutcomeKind.voided, board.roster.students.length);
  });

  /// Runs an action on the roll on screen. It goes through, and the roll is read again (the register is now there, or
  /// gone), or it is refused, and the person sees why: over the roll when it stands, and over the roll read again when
  /// the refusal says it was out of date.
  Future<void> _act(
    Emitter<AttendanceState> emit,
    Future<AttendanceOutcome> Function(BoardLoaded board) work,
  ) async {
    if (state case final AttendanceReady ready when ready.board is BoardLoaded) {
      final board = ready.board as BoardLoaded;
      if (board.saving) return;
      emit(ready.copyWith(board: board.copyWith(saving: true, failure: () => null)));
      try {
        final outcome = await work(board);
        await _read(emit, outcome: outcome);
      } on ApiFailure catch (failure) {
        if (_outOfDate.contains(failure.code)) {
          await _read(emit, failure: failure);
        } else {
          emit(ready.copyWith(board: board.copyWith(saving: false, failure: () => failure)));
        }
      }
    }
  }
}
