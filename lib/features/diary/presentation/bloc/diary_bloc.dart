import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_repository.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:equatable/equatable.dart';

sealed class DiaryEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, and Try again after the classes could not be read.
final class DiaryStarted extends DiaryEvent {
  const new();
}

/// Another class chosen: its section has to be chosen too, unless it has only one.
final class DiaryClassChosen extends DiaryEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class DiarySectionChosen extends DiaryEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

/// Another day, `YYYY-MM-DD`.
final class DiaryDayChosen extends DiaryEvent {
  const new(this.day);

  final String day;

  @override
  List<Object?> get props => [day];
}

/// Try again after the entries could not be read, and after an entry was added or changed: [day] is the day it is
/// written for, which the screen then shows.
final class DiaryRead extends DiaryEvent {
  const new({this.day});

  final String? day;

  @override
  List<Object?> get props => [day];
}

/// Delete one entry (DIA-04).
final class DiaryEntryRemoved extends DiaryEvent {
  const new(this.entry);

  final DiaryEntry entry;

  @override
  List<Object?> get props => [entry];
}

/// What the screen shows under the filters.
sealed class DiaryBoard extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// No section is chosen yet.
class DiaryBoardEmpty extends DiaryBoard {
  const new();
}

class DiaryBoardLoading extends DiaryBoard {
  const new();
}

class DiaryBoardFailed extends DiaryBoard {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The entries of the day, in the order written. [removing] is the entry being deleted; [failure] is why the last
/// delete was refused.
class DiaryBoardLoaded extends DiaryBoard {
  const new(this.entries, {this.removing, this.failure});

  final List<DiaryEntry> entries;
  final String? removing;
  final ApiFailure? failure;

  @override
  List<Object?> get props => [entries, removing, failure];
}

sealed class DiaryState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class DiaryLoading extends DiaryState {
  const new();
}

/// The classes could not be read.
class DiaryFailed extends DiaryState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The classes and sections to choose from (none for a parent, who reads their child's), what is chosen, and the
/// entries of it.
class DiaryReady extends DiaryState {
  const new({
    required this.classes,
    required this.sections,
    required this.day,
    this.classId,
    this.sectionId,
    this.board = const DiaryBoardEmpty(),
  });

  final List<ClassChoice> classes;
  final List<SectionChoice> sections;
  final String? classId;
  final String? sectionId;

  /// `YYYY-MM-DD`.
  final String day;
  final DiaryBoard board;

  List<SectionChoice> get sectionsInClass => sections.inClass(classId);

  DiaryReady copyWith({
    String? Function()? classId,
    String? Function()? sectionId,
    String? day,
    DiaryBoard? board,
  }) => DiaryReady(
    classes: classes,
    sections: sections,
    classId: classId == null ? this.classId : classId(),
    sectionId: sectionId == null ? this.sectionId : sectionId(),
    day: day ?? this.day,
    board: board ?? this.board,
  );

  @override
  List<Object?> get props => [classes, sections, classId, sectionId, day, board];
}

/// The diary of a day (API design 10.14a): staff choose a class and a section of the Institution, a parent reads the
/// section their child sits in. The entries are those of the section and day chosen; a deleted entry leaves the list.
class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  /// Staff read the sections of [institutionId]; a parent reads the diary of [studentId].
  new(this._diary, this._attendance, {this.institutionId, this.studentId, this._clock = DateTime.now})
    : assert((institutionId == null) != (studentId == null), 'a screen reads sections or one child'),
      super(const DiaryLoading()) {
    on<DiaryStarted>(_onStarted);
    on<DiaryClassChosen>(_onClassChosen);
    on<DiarySectionChosen>(_onSectionChosen);
    on<DiaryDayChosen>(_onDayChosen);
    on<DiaryRead>((event, emit) => _read(emit, day: event.day));
    on<DiaryEntryRemoved>(_onRemoved);
  }

  final DiaryRepository _diary;
  final AttendanceRepository _attendance;
  final String? institutionId;
  final String? studentId;
  final DateTime Function() _clock;

  /// The entries being read, so an answer for a section or day the person has left is not shown.
  int _reading = 0;

  void _ready(void Function(DiaryReady ready) work) {
    if (state case final DiaryReady ready) work(ready);
  }

  Future<void> _onStarted(DiaryStarted event, Emitter<DiaryState> emit) async {
    final day = Formatters.schoolDay(_clock());
    if (studentId != null) {
      emit(DiaryReady(classes: const [], sections: const [], day: day));
      await _read(emit);
      return;
    }
    emit(const DiaryLoading());
    try {
      // Every section of the Institution, as the attendance screen offers; a teacher is refused the ones they neither
      // lead nor teach when they read them.
      final choices = await _attendance.sections(institutionId!);
      final single = choices.classes.length == 1 ? choices.classes.single.id : null;
      emit(DiaryReady(classes: choices.classes, sections: choices.sections, day: day, classId: single));
      if (single != null) _chooseOnlySection();
    } on ApiFailure catch (failure) {
      emit(DiaryFailed(failure));
    }
  }

  /// A school with one class and one section has nothing to choose.
  void _chooseOnlySection() => _ready((ready) {
    final only = ready.sectionsInClass;
    if (only.length == 1) add(DiarySectionChosen(only.single.id));
  });

  void _onClassChosen(DiaryClassChosen event, Emitter<DiaryState> emit) => _ready((ready) {
    final id = event.id;
    if (id == null || id == ready.classId || _busy(ready)) return;
    _reading++;
    emit(ready.copyWith(classId: () => id, sectionId: () => null, board: const DiaryBoardEmpty()));
    _chooseOnlySection();
  });

  Future<void> _onSectionChosen(DiarySectionChosen event, Emitter<DiaryState> emit) async {
    if (state case final DiaryReady ready) {
      final id = event.id;
      if (id == null || id == ready.sectionId || _busy(ready)) return;
      emit(ready.copyWith(sectionId: () => id));
      await _read(emit);
    }
  }

  Future<void> _onDayChosen(DiaryDayChosen event, Emitter<DiaryState> emit) async {
    if (state case final DiaryReady ready) {
      if (event.day == ready.day || _busy(ready)) return;
      emit(ready.copyWith(day: event.day));
      await _read(emit);
    }
  }

  /// No other choice is taken while an entry is being deleted: its answer belongs to the list that was on screen.
  bool _busy(DiaryReady ready) => switch (ready.board) {
    DiaryBoardLoaded(:final removing) => removing != null,
    _ => false,
  };

  /// Reads the entries of the section (or child) and day chosen; [day] first moves the screen to that day.
  Future<void> _read(Emitter<DiaryState> emit, {String? day}) async {
    if (state case final DiaryReady shown when studentId != null || shown.sectionId != null) {
      final ready = day == null ? shown : shown.copyWith(day: day);
      final token = ++_reading;
      emit(ready.copyWith(board: const DiaryBoardLoading()));
      DiaryBoard board;
      try {
        final entries = studentId != null
            ? await _diary.ofChild(studentId!, ready.day)
            : await _diary.ofSection(ready.sectionId!, ready.day);
        board = DiaryBoardLoaded(entries);
      } on ApiFailure catch (failure) {
        board = DiaryBoardFailed(failure);
      }
      if (token != _reading) return;
      if (state case final DiaryReady current) emit(current.copyWith(board: board));
    }
  }

  Future<void> _onRemoved(DiaryEntryRemoved event, Emitter<DiaryState> emit) async {
    if (state case final DiaryReady ready when ready.board is DiaryBoardLoaded) {
      final board = ready.board as DiaryBoardLoaded;
      if (board.removing != null) return;
      emit(ready.copyWith(board: DiaryBoardLoaded(board.entries, removing: event.entry.id)));
      try {
        await _diary.remove(event.entry.id);
        emit(
          ready.copyWith(
            board: DiaryBoardLoaded([
              for (final entry in board.entries)
                if (entry.id != event.entry.id) entry,
            ]),
          ),
        );
      } on ApiFailure catch (failure) {
        // An entry already removed is no longer in the list the server gives, so the list is read again.
        if (failure.code == 'NOT_FOUND') {
          await _read(emit);
        } else {
          emit(ready.copyWith(board: DiaryBoardLoaded(board.entries, failure: failure)));
        }
      }
    }
  }
}
