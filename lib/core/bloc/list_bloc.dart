import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:equatable/equatable.dart';

/// Opening the screen is [ListRequested]; a bloc adds the changes its cards offer as events of its own.
abstract class ListEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, Try again after a failure, and coming back from a form that saved.
final class ListRequested extends ListEvent {
  const new();
}

sealed class ListState<T> extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class ListLoading<T> extends ListState<T> {
  const new();
}

class ListFailed<T> extends ListState<T> {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The [items]. [busyId] is the item a change is on its way for; [actionFailure] is why the last change was refused,
/// and [changed] is the item the last one went through for ([notice] says which kind, when a list has more than one).
class ListLoaded<T> extends ListState<T> {
  const new(this.items, {this.busyId, this.actionFailure, this.changed, this.notice});

  final List<T> items;
  final String? busyId;
  final ApiFailure? actionFailure;
  final T? changed;
  final Enum? notice;

  @override
  List<Object?> get props => [items, busyId, actionFailure, changed, notice];
}

/// A screen that lists one kind of record and changes one at a time from its card (deactivate, make current, ...): the
/// load, the change, and the list read again after it. A change moves what the list shows, and a refusal such as 404
/// or VERSION_CONFLICT means the list on screen is out of date, so it is always read again. A bloc names its changes as
/// events of its own and runs them with [change].
abstract class ListBloc<T> extends Bloc<ListEvent, ListState<T>> {
  new() : super(ListLoading<T>()) {
    on<ListRequested>(_onRequested);
  }

  /// Reads the items.
  Future<List<T>> read();

  Future<void> _onRequested(ListRequested event, Emitter<ListState<T>> emit) async {
    emit(ListLoading<T>());
    try {
      emit(ListLoaded<T>(await read()));
    } on ApiFailure catch (failure) {
      emit(ListFailed<T>(failure));
    }
  }

  /// Runs [run] for [item] (one change at a time, and only once the list is shown), then reads the list again.
  Future<void> change(
    Emitter<ListState<T>> emit,
    T item,
    String id,
    Future<Object?> Function() run, {
    Enum? notice,
  }) async {
    if (state case final ListLoaded<T> loaded when loaded.busyId == null) {
      emit(ListLoaded<T>(loaded.items, busyId: id));
      ApiFailure? refused;
      try {
        await run();
      } on ApiFailure catch (failure) {
        refused = failure;
      }
      try {
        emit(
          ListLoaded<T>(
            await read(),
            actionFailure: refused,
            changed: refused == null ? item : null,
            notice: refused == null ? notice : null,
          ),
        );
      } on ApiFailure catch (failure) {
        emit(ListFailed<T>(failure));
      }
    }
  }
}
