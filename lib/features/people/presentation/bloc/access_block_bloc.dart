import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:equatable/equatable.dart';

sealed class AccessBlockEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Block, or lift the block, whichever the record is not in now.
final class AccessBlockToggled extends AccessBlockEvent {
  const new();
}

sealed class AccessBlockState<T> extends Equatable {
  const new(this.record);

  /// The record as the API last answered.
  final T record;

  @override
  List<Object?> get props => [record];
}

class AccessBlockIdle<T> extends AccessBlockState<T> {
  const new(super.record);
}

class AccessBlockWorking<T> extends AccessBlockState<T> {
  const new(super.record);
}

/// The last block or lift was refused. For a record that was already as asked (409 `INVALID_STATE`) the [record] is the
/// record read again.
class AccessBlockRefused<T> extends AccessBlockState<T> {
  const new(super.record, this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [record, failure];
}

/// Blocks a person's access, or lifts the block, on the profile of one record of type [T]: a staff member's own access
/// (STF-06, STF-07) or the guardians' access to one student (STU-06, STU-07). Each says which calls to make.
class AccessBlockBloc<T> extends Bloc<AccessBlockEvent, AccessBlockState<T>> {
  new(
    T record, {
    required this.isBlocked,
    required this.block,
    required this.unblock,
    required this.read,
  }) : super(AccessBlockIdle(record)) {
    on<AccessBlockToggled>(_onToggled);
  }

  /// Whether the record is blocked now.
  final bool Function(T record) isBlocked;

  /// The block, the lift and a plain read of the record; each answers the record as it is after.
  final Future<T> Function(T record) block;
  final Future<T> Function(T record) unblock;
  final Future<T> Function(T record) read;

  /// Someone else already blocked, or lifted, the record: the screen takes it as it is now, so what it says is true and
  /// the next press asks for the right thing. When it cannot be read, the screen stays as it was.
  Future<T> _current(T record) async {
    try {
      return await read(record);
    } on ApiFailure {
      return record;
    }
  }

  Future<void> _onToggled(AccessBlockToggled event, Emitter<AccessBlockState<T>> emit) async {
    if (state is AccessBlockWorking<T>) return;
    final record = state.record;
    emit(AccessBlockWorking(record));
    try {
      emit(AccessBlockIdle(isBlocked(record) ? await unblock(record) : await block(record)));
    } on ApiFailure catch (failure) {
      emit(AccessBlockRefused(failure.code == 'INVALID_STATE' ? await _current(record) : record, failure));
    }
  }
}
