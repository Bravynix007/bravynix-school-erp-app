import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:equatable/equatable.dart';

sealed class StaffBlockEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Block, or lift the block, whichever the staff member is not in now.
final class StaffBlockToggled extends StaffBlockEvent {
  const new();
}

sealed class StaffBlockState extends Equatable {
  const new(this.member);

  /// The staff member as the API last answered.
  final StaffMember member;

  @override
  List<Object?> get props => [member];
}

class StaffBlockIdle extends StaffBlockState {
  const new(super.member);
}

class StaffBlockWorking extends StaffBlockState {
  const new(super.member);
}

/// The last block or lift was refused. For a record that was already as asked (409 `INVALID_STATE`) the [member] is
/// the record read again.
class StaffBlockRefused extends StaffBlockState {
  const new(super.member, this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [member, failure];
}

/// Blocks a staff member's access in the Society (STF-06) or lifts the block (STF-07).
class StaffBlockBloc extends Bloc<StaffBlockEvent, StaffBlockState> {
  new(this._staff, StaffMember member) : super(StaffBlockIdle(member)) {
    on<StaffBlockToggled>(_onToggled);
  }

  final StaffRepository _staff;

  /// Someone else already blocked, or lifted, the record: the screen takes it as it is now (STF-03), so what it says is
  /// true and the next press asks for the right thing. When it cannot be read, the screen stays as it was.
  Future<StaffMember> _current(StaffMember member) async {
    try {
      return await _staff.member(member.id);
    } on ApiFailure {
      return member;
    }
  }

  Future<void> _onToggled(StaffBlockToggled event, Emitter<StaffBlockState> emit) async {
    if (state is StaffBlockWorking) return;
    final member = state.member;
    emit(StaffBlockWorking(member));
    try {
      emit(StaffBlockIdle(member.isBlocked ? await _staff.unblock(member.id) : await _staff.block(member.id)));
    } on ApiFailure catch (failure) {
      emit(StaffBlockRefused(failure.code == 'INVALID_STATE' ? await _current(member) : member, failure));
    }
  }
}
