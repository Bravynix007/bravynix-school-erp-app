import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/storage/child_choice_store.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:equatable/equatable.dart';

sealed class ActiveChildEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The children the signed-in parent guards, as the session now has them: empty for any other role and once signed
/// out. Sent on every change of session, so a link that ended or a block that was lifted shows without a restart.
final class ActiveChildChildrenChanged extends ActiveChildEvent {
  const new(this.children);

  final List<LinkedChild> children;

  @override
  List<Object?> get props => [children];
}

final class ActiveChildChosen extends ActiveChildEvent {
  const new(this.studentId);

  final String studentId;

  @override
  List<Object?> get props => [studentId];
}

sealed class ActiveChildState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The person is not a parent, or has no child.
class ActiveChildNone extends ActiveChildState {
  const new();
}

class ActiveChildReady extends ActiveChildState {
  const new({required this.children, required this.selected});

  final List<LinkedChild> children;
  final LinkedChild selected;

  @override
  List<Object?> get props => [children, selected];
}

/// Which child every parent screen shows (attendance, diary, events): the one chosen last if the parent still has
/// them, else the first whose data is open, else the first. A blocked child can still be chosen, to read why the data
/// is closed; the siblings keep working (API design 6.5).
class ActiveChildBloc extends Bloc<ActiveChildEvent, ActiveChildState> {
  new(this._choice) : super(const ActiveChildNone()) {
    on<ActiveChildChildrenChanged>(_onChildrenChanged);
    on<ActiveChildChosen>(_onChosen);
  }

  final ChildChoiceStore _choice;

  Future<void> _onChildrenChanged(ActiveChildChildrenChanged event, Emitter<ActiveChildState> emit) async {
    final children = event.children;
    if (children.isEmpty) {
      emit(const ActiveChildNone());
      return;
    }
    final remembered = await _choice.read();
    emit(
      ActiveChildReady(
        children: children,
        selected:
            children.where((child) => child.studentId == remembered).firstOrNull ??
            children.where((child) => !child.isBlocked).firstOrNull ??
            children.first,
      ),
    );
  }

  Future<void> _onChosen(ActiveChildChosen event, Emitter<ActiveChildState> emit) async {
    if (state case final ActiveChildReady ready) {
      final chosen = ready.children.where((child) => child.studentId == event.studentId).firstOrNull;
      if (chosen == null || chosen == ready.selected) return;
      emit(ActiveChildReady(children: ready.children, selected: chosen));
      await _choice.write(chosen.studentId);
    }
  }
}
