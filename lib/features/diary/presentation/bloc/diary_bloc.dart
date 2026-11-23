import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_repository.dart';
import 'package:equatable/equatable.dart';

sealed class DiaryEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The diary of [day] is read: that of the section [sectionId] for staff, of the child shown for a parent.
final class DiaryRead extends DiaryEvent {
  const new({required this.day, this.sectionId});

  final String? sectionId;

  /// `YYYY-MM-DD`.
  final String day;

  @override
  List<Object?> get props => [sectionId, day];
}

/// No section is chosen: there is nothing to read.
final class DiaryCleared extends DiaryEvent {
  const new();
}

/// The diary on screen is read again: Try again, and after an entry was added or changed.
final class DiaryReloaded extends DiaryEvent {
  const new();
}

/// Delete one entry (DIA-04).
final class DiaryEntryRemoved extends DiaryEvent {
  const new(this.entry);

  final DiaryEntry entry;

  @override
  List<Object?> get props => [entry];
}

/// What the screen shows under the fields.
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

/// The diary of a day (API design 10.14a): the entries of the section (or child) and day the screen chose, in the order
/// written; a deleted entry leaves the list.
class DiaryBloc extends Bloc<DiaryEvent, DiaryBoard> {
  /// Staff read the section they choose; a parent reads the diary of [studentId], the child shown.
  new(this._diary, {this.studentId}) : super(const DiaryBoardEmpty()) {
    on<DiaryRead>(_onRead);
    on<DiaryCleared>(_onCleared);
    on<DiaryReloaded>((event, emit) => _read(emit));
    on<DiaryEntryRemoved>(_onRemoved);
  }

  final DiaryRepository _diary;
  final String? studentId;

  /// What is on screen, and the entries being read of it, so an answer for a section or day the person has left is not
  /// shown.
  String? _sectionId;
  String _day = '';
  int _reading = 0;

  Future<void> _onRead(DiaryRead event, Emitter<DiaryBoard> emit) {
    _sectionId = event.sectionId;
    _day = event.day;
    return _read(emit);
  }

  void _onCleared(DiaryCleared event, Emitter<DiaryBoard> emit) {
    _sectionId = null;
    _reading++;
    emit(const DiaryBoardEmpty());
  }

  Future<void> _read(Emitter<DiaryBoard> emit) async {
    if (studentId == null && _sectionId == null) return;
    final token = ++_reading;
    emit(const DiaryBoardLoading());
    DiaryBoard board;
    try {
      final entries = studentId != null
          ? await _diary.ofChild(studentId!, _day)
          : await _diary.ofSection(_sectionId!, _day);
      board = DiaryBoardLoaded(entries);
    } on ApiFailure catch (failure) {
      board = DiaryBoardFailed(failure);
    }
    if (token == _reading) emit(board);
  }

  Future<void> _onRemoved(DiaryEntryRemoved event, Emitter<DiaryBoard> emit) async {
    if (state case final DiaryBoardLoaded board when board.removing == null) {
      emit(DiaryBoardLoaded(board.entries, removing: event.entry.id));
      try {
        await _diary.remove(event.entry.id);
        emit(
          DiaryBoardLoaded([
            for (final entry in board.entries)
              if (entry.id != event.entry.id) entry,
          ]),
        );
      } on ApiFailure catch (failure) {
        // An entry already removed is no longer in the list the server gives, so the list is read again.
        if (failure.code == 'NOT_FOUND') {
          await _read(emit);
        } else {
          emit(DiaryBoardLoaded(board.entries, failure: failure));
        }
      }
    }
  }
}
