import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';
import 'package:equatable/equatable.dart';

class RoleState extends Equatable {
  const new({this.choosing, this.chosen, this.failure});

  /// The context being switched to: the list is locked while it is set.
  final AuthContext? choosing;

  /// Set when the server accepted the switch; the page hands it to the session bloc.
  final AuthContext? chosen;
  final ApiFailure? failure;

  bool get isSubmitting => choosing != null;

  @override
  List<Object?> get props => [choosing, chosen, failure];
}

sealed class RoleEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

final class RoleChosen extends RoleEvent {
  const new(this.context);

  final AuthContext context;

  @override
  List<Object?> get props => [context];
}

/// Picks the role the session acts as (AUTH-06).
class RoleBloc extends Bloc<RoleEvent, RoleState> {
  new(this._auth, {this.current}) : super(const RoleState()) {
    on<RoleChosen>(_onChosen);
  }

  final AuthRepository _auth;

  /// The role already active, when the person is switching rather than choosing for the first time.
  final AuthContext? current;

  Future<void> _onChosen(RoleChosen event, Emitter<RoleState> emit) async {
    if (state.isSubmitting) return;
    final context = event.context;
    // Choosing the role already in use needs no call.
    if (context == current) {
      emit(RoleState(chosen: context));
      return;
    }
    emit(RoleState(choosing: context));
    try {
      await _auth.switchContext(context);
      emit(RoleState(chosen: context));
    } on ApiFailure catch (failure) {
      emit(RoleState(failure: failure));
    }
  }
}
