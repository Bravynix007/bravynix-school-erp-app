import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/notifications/domain/inbox_item.dart';
import 'package:bravynix_school_erp/features/notifications/domain/notifications_repository.dart';
import 'package:equatable/equatable.dart';

sealed class InboxEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the inbox, choosing another tab, and Try again: the first page of [tab].
final class InboxRequested extends InboxEvent {
  const new(this.tab);

  final InboxTab tab;

  @override
  List<Object?> get props => [tab];
}

/// Load more, at the end of the list.
final class InboxMoreRequested extends InboxEvent {
  const new();
}

/// The person opened a notice: it is marked read, if it was not.
final class InboxItemOpened extends InboxEvent {
  const new(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// The tick at the top: every unread notice of the tab is marked read.
final class InboxMarkedAllRead extends InboxEvent {
  const new();
}

/// The trash icon, once confirmed: every notice of the tab is deleted.
final class InboxCleared extends InboxEvent {
  const new();
}

sealed class InboxState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class InboxLoading extends InboxState {
  const new(this.tab);

  final InboxTab tab;

  @override
  List<Object?> get props => [tab];
}

class InboxFailed extends InboxState {
  const new(this.tab, this.failure);

  final InboxTab tab;
  final ApiFailure failure;

  @override
  List<Object?> get props => [tab, failure];
}

/// The pages of [tab] read so far. [working]: a change to the whole tab is on its way. [actionFailure] is why the last
/// change was refused, [moreFailure] why the last Load more failed.
class InboxLoaded extends InboxState {
  const new(
    this.tab,
    this.items, {
    this.nextCursor,
    this.loadingMore = false,
    this.moreFailure,
    this.working = false,
    this.actionFailure,
  });

  final InboxTab tab;
  final List<InboxItem> items;
  final String? nextCursor;
  final bool loadingMore;
  final ApiFailure? moreFailure;
  final bool working;
  final ApiFailure? actionFailure;

  bool get hasMore => nextCursor != null;
  bool get hasUnread => items.any((item) => !item.isRead);

  InboxLoaded copyWith({
    List<InboxItem>? items,
    bool? loadingMore,
    ApiFailure? moreFailure,
    bool? working,
    ApiFailure? actionFailure,
  }) => InboxLoaded(
    tab,
    items ?? this.items,
    nextCursor: nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    moreFailure: moreFailure,
    working: working ?? this.working,
    actionFailure: actionFailure,
  );

  @override
  List<Object?> get props => [tab, items, nextCursor, loadingMore, moreFailure, working, actionFailure];
}

/// The inbox of the person (NTF-01, NTF-03 to NTF-05), one tab at a time, newest first and read by cursor.
class InboxBloc extends Bloc<InboxEvent, InboxState> {
  new(this._notifications, InboxTab first) : super(InboxLoading(first)) {
    on<InboxRequested>(_onRequested);
    on<InboxMoreRequested>(_onMore);
    on<InboxItemOpened>(_onOpened);
    on<InboxMarkedAllRead>(_onMarkedAllRead);
    on<InboxCleared>(_onCleared);
  }

  final NotificationsRepository _notifications;

  /// Counts the times a tab was asked for again, so the answer to an earlier ask can tell it is out of date.
  int _round = 0;

  InboxTab get _tab => switch (state) {
    InboxLoading(:final tab) || InboxFailed(:final tab) || InboxLoaded(:final tab) => tab,
  };

  Future<void> _onRequested(InboxRequested event, Emitter<InboxState> emit) async {
    final round = ++_round;
    emit(InboxLoading(event.tab));
    try {
      final page = await _notifications.inbox(event.tab);
      if (round == _round) emit(InboxLoaded(event.tab, page.items, nextCursor: page.nextCursor));
    } on ApiFailure catch (failure) {
      if (round == _round) emit(InboxFailed(event.tab, failure));
    }
  }

  Future<void> _onMore(InboxMoreRequested event, Emitter<InboxState> emit) async {
    if (state case final InboxLoaded loaded when loaded.hasMore && !loaded.loadingMore && !loaded.working) {
      final round = _round;
      emit(loaded.copyWith(loadingMore: true));
      try {
        final page = await _notifications.inbox(loaded.tab, cursor: loaded.nextCursor);
        if (round == _round) {
          emit(InboxLoaded(loaded.tab, [...loaded.items, ...page.items], nextCursor: page.nextCursor));
        }
      } on ApiFailure catch (failure) {
        if (round == _round) emit(loaded.copyWith(moreFailure: failure));
      }
    }
  }

  Future<void> _onOpened(InboxItemOpened event, Emitter<InboxState> emit) async {
    if (state case final InboxLoaded loaded) {
      final item = loaded.items.where((item) => item.id == event.id).firstOrNull;
      if (item == null || item.isRead) return;
      final round = _round;
      try {
        final read = await _notifications.markRead(item.id);
        if (round == _round && state is InboxLoaded) {
          final now = state as InboxLoaded;
          emit(now.copyWith(items: now.items.map((entry) => entry.id == read.id ? read : entry).toList()));
        }
      } on ApiFailure catch (failure) {
        if (round == _round && state is InboxLoaded) emit((state as InboxLoaded).copyWith(actionFailure: failure));
      }
    }
  }

  Future<void> _onMarkedAllRead(InboxMarkedAllRead event, Emitter<InboxState> emit) =>
      _change(emit, () => _notifications.markAllRead(tab: _tab));

  Future<void> _onCleared(InboxCleared event, Emitter<InboxState> emit) =>
      _change(emit, () => _notifications.clear(tab: _tab));

  /// Runs [run] on the whole tab, then reads the tab again: what it holds has moved.
  Future<void> _change(Emitter<InboxState> emit, Future<void> Function() run) async {
    if (state case final InboxLoaded loaded when !loaded.working) {
      final round = ++_round;
      emit(loaded.copyWith(working: true));
      ApiFailure? refused;
      try {
        await run();
      } on ApiFailure catch (failure) {
        refused = failure;
      }
      try {
        final page = await _notifications.inbox(loaded.tab);
        if (round == _round) {
          emit(InboxLoaded(loaded.tab, page.items, nextCursor: page.nextCursor, actionFailure: refused));
        }
      } on ApiFailure catch (failure) {
        if (round == _round) emit(InboxFailed(loaded.tab, failure));
      }
    }
  }
}
