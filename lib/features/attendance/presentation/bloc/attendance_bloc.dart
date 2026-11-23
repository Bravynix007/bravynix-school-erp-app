import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_day.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

sealed class AttendanceEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The section and day the screen chose, or null when no section is chosen: the roll of it is read.
final class AttendanceSelected extends AttendanceEvent {
  const new(this.selection);

  final SectionDay? selection;

  @override
  List<Object?> get props => [selection];
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

/// The roll of the section and day chosen, and what the last action did.
class AttendanceState extends Equatable {
  const new({this.board = const BoardEmpty(), this.outcome});

  final AttendanceBoard board;

  /// What the last action did; null after any later change, so the screen says it once.
  final AttendanceOutcome? outcome;

  AttendanceState copyWith({AttendanceBoard? board, AttendanceOutcome? outcome}) =>
      AttendanceState(board: board ?? this.board, outcome: outcome);

  @override
  List<Object?> get props => [board, outcome];
}

/// Taking a section's attendance for a day, correcting it and voiding it (API design 10.10 to 10.12a). A register is one
/// per section and day; everyone is Present until a mark says otherwise, so only the others are sent. A repeat of the
/// same submission, after an answer that was lost, carries the same Idempotency-Key and finds the first one done; any
/// change to the marks or the roll starts a new attempt.
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  new(this._attendance, {String Function()? newKey})
    : _newKey = newKey ?? const Uuid().v4,
      super(const AttendanceState()) {
    on<AttendanceSelected>(_onSelected);
    on<AttendanceRollRetried>((event, emit) => _read(emit));
    on<AttendanceMarked>(_onMarked);
    on<AttendanceSubmitted>(_onSubmitted);
    on<AttendanceCorrected>(_onCorrected);
    on<AttendanceVoided>(_onVoided);
  }

  final AttendanceRepository _attendance;
  final String Function() _newKey;
  String? _key;

  /// The section and day on screen, and the roll being read of them, so an answer for a section or day the person has
  /// left is not shown.
  SectionDay? _selection;
  int _reading = 0;

  /// Refusals that mean the roll on screen is out of date: the register was taken or voided, or a student joined or
  /// left, since it was read.
  static const _outOfDate = {
    'ROSTER_CHANGED',
    'STUDENT_NOT_IN_SECTION',
    'ATTENDANCE_ALREADY_SUBMITTED',
    'VERSION_CONFLICT',
    'SESSION_VOIDED',
  };

  Future<void> _onSelected(AttendanceSelected event, Emitter<AttendanceState> emit) {
    _selection = event.selection;
    if (_selection != null) return _read(emit);
    _reading++;
    emit(const AttendanceState());
    return Future.value();
  }

  /// Reads the roll of the chosen section and day; [failure] is a refusal to show over it (the roll it came from was out
  /// of date), and [outcome] what the last action did.
  Future<void> _read(Emitter<AttendanceState> emit, {ApiFailure? failure, AttendanceOutcome? outcome}) async {
    final selection = _selection;
    if (selection == null) return;
    final token = ++_reading;
    _key = null;
    emit(state.copyWith(board: const BoardLoading()));
    AttendanceBoard board;
    try {
      final roster = await _attendance.roster(selection.sectionId, selection.day);
      board = BoardLoaded(roster, const {}, failure: failure);
    } on ApiFailure catch (failed) {
      board = BoardFailed(failed);
    }
    if (token == _reading) emit(state.copyWith(board: board, outcome: outcome));
  }

  void _onMarked(AttendanceMarked event, Emitter<AttendanceState> emit) {
    if (state.board case final BoardLoaded board when !board.saving) {
      _key = null;
      emit(
        state.copyWith(
          board: board.copyWith(marks: {...board.marks, event.enrolmentId: event.mark}, failure: () => null),
        ),
      );
    }
  }

  Future<void> _onSubmitted(AttendanceSubmitted event, Emitter<AttendanceState> emit) => _act(
    emit,
    (board) async {
      final rosterCount = await _attendance.submit(
        sectionId: board.roster.sectionId,
        day: board.roster.day,
        rosterCount: board.roster.students.length,
        exceptions: board.exceptions,
        idempotencyKey: _key ??= _newKey(),
      );
      return AttendanceOutcome(AttendanceOutcomeKind.submitted, rosterCount);
    },
  );

  Future<void> _onCorrected(AttendanceCorrected event, Emitter<AttendanceState> emit) => _act(emit, (board) async {
    await _attendance.correct(board.roster.taken!.id, board.roster.taken!.version, board.changes);
    return AttendanceOutcome(AttendanceOutcomeKind.corrected, board.roster.students.length);
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
    if (state.board case final BoardLoaded board) {
      if (board.saving) return;
      emit(state.copyWith(board: board.copyWith(saving: true, failure: () => null)));
      try {
        final outcome = await work(board);
        await _read(emit, outcome: outcome);
      } on ApiFailure catch (failure) {
        if (_outOfDate.contains(failure.code)) {
          await _read(emit, failure: failure);
        } else {
          emit(state.copyWith(board: board.copyWith(saving: false, failure: () => failure)));
        }
      }
    }
  }
}
