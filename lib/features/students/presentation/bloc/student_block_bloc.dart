import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:equatable/equatable.dart';

sealed class StudentBlockEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Block the guardians' access to the child, or lift the block, whichever the student is not in now.
final class StudentBlockToggled extends StudentBlockEvent {
  const new();
}

sealed class StudentBlockState extends Equatable {
  const new(this.record);

  /// The student as the API last answered.
  final StudentRecord record;

  @override
  List<Object?> get props => [record];
}

class StudentBlockIdle extends StudentBlockState {
  const new(super.record);
}

class StudentBlockWorking extends StudentBlockState {
  const new(super.record);
}

/// The last block or lift was refused. For a student that was already as asked (409 `INVALID_STATE`) the [record] is
/// the student read again.
class StudentBlockRefused extends StudentBlockState {
  const new(super.record, this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [record, failure];
}

/// Blocks the guardians' access to one child (STU-06) or lifts the block (STU-07).
class StudentBlockBloc extends Bloc<StudentBlockEvent, StudentBlockState> {
  new(this._students, StudentRecord record) : super(StudentBlockIdle(record)) {
    on<StudentBlockToggled>(_onToggled);
  }

  final StudentsRepository _students;

  /// Someone else already blocked, or lifted, the block: the screen takes the student as they are now (STU-03), so
  /// what it says is true and the next press asks for the right thing. When they cannot be read, it stays as it was.
  Future<StudentRecord> _current(StudentRecord record) async {
    try {
      return await _students.student(record.id);
    } on ApiFailure {
      return record;
    }
  }

  Future<void> _onToggled(StudentBlockToggled event, Emitter<StudentBlockState> emit) async {
    if (state is StudentBlockWorking) return;
    final record = state.record;
    emit(StudentBlockWorking(record));
    try {
      emit(StudentBlockIdle(record.isBlocked ? await _students.unblock(record.id) : await _students.block(record.id)));
    } on ApiFailure catch (failure) {
      emit(StudentBlockRefused(failure.code == 'INVALID_STATE' ? await _current(record) : record, failure));
    }
  }
}
