import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:equatable/equatable.dart';

abstract class PagedListEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, Try again after a failure, and coming back from a form that saved: the first page again.
final class PagedListRequested extends PagedListEvent {
  const new();
}

/// What was typed in the search box, once it is sent. Empty clears the search; one letter is not enough to search for
/// (the API wants two, API design 13.1), so it changes nothing.
final class PagedListSearched extends PagedListEvent {
  const new(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Load more, at the end of the list.
final class PagedListMoreRequested extends PagedListEvent {
  const new();
}

sealed class PagedListState<T> extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class PagedListLoading<T> extends PagedListState<T> {
  const new();
}

class PagedListFailed<T> extends PagedListState<T> {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The pages read so far. [query] is the search they answer; [hasMore] says there is a page after the last one read.
/// [busyId], [actionFailure] and [changed] are those of `ListLoaded`: the item a change is on its way for, why the
/// last change was refused, and the item it went through for. [moreFailure] is why the last Load more failed.
class PagedListLoaded<T> extends PagedListState<T> {
  const new(
    this.items, {
    this.query = '',
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.moreFailure,
    this.busyId,
    this.actionFailure,
    this.changed,
  });

  final List<T> items;
  final String query;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final ApiFailure? moreFailure;
  final String? busyId;
  final ApiFailure? actionFailure;
  final T? changed;

  @override
  List<Object?> get props => [items, query, page, hasMore, loadingMore, moreFailure, busyId, actionFailure, changed];
}

/// A screen that lists one kind of record a page at a time, with a search, and changes one at a time from its card.
/// Like `ListBloc`, but the list is read a page at a time and asked for again from the first page after a change: a
/// change moves what the list shows, so the pages already read are not trusted. An answer that arrives after the list
/// was asked for again (a new search, a change) is dropped, so a change may start while Load more is on its way, and a
/// search is ignored while a change is going (the screen locks its search box meanwhile).
abstract class PagedListBloc<T> extends Bloc<PagedListEvent, PagedListState<T>> {
  new() : super(PagedListLoading<T>()) {
    on<PagedListRequested>((event, emit) => _reload(emit));
    on<PagedListSearched>(_onSearched);
    on<PagedListMoreRequested>(_onMore);
  }

  /// Reads [page] (from 1) of the items matching [query], which is empty when nothing is searched for.
  Future<ItemsPage<T>> read(int page, String query);

  String _query = '';

  /// Counts the times the list was asked for again, so an answer to an earlier ask can tell it is out of date.
  int _round = 0;

  PagedListLoaded<T> _loaded(ItemsPage<T> page, {ApiFailure? actionFailure, T? changed}) => PagedListLoaded<T>(
    page.items,
    query: _query,
    page: page.page,
    hasMore: page.hasMore,
    actionFailure: actionFailure,
    changed: changed,
  );

  Future<void> _reload(Emitter<PagedListState<T>> emit) async {
    final round = ++_round;
    emit(PagedListLoading<T>());
    try {
      final page = await read(1, _query);
      if (round == _round) emit(_loaded(page));
    } on ApiFailure catch (failure) {
      if (round == _round) emit(PagedListFailed<T>(failure));
    }
  }

  Future<void> _onSearched(PagedListSearched event, Emitter<PagedListState<T>> emit) async {
    final text = event.text.trim();
    // A search moves the round on, which would drop the outcome of the change that is going, so it is ignored (the
    // screen locks its search box meanwhile).
    if (text == _query ||
        text.length == 1 ||
        (state is PagedListLoaded<T> && (state as PagedListLoaded<T>).busyId != null)) {
      return;
    }
    _query = text;
    await _reload(emit);
  }

  Future<void> _onMore(PagedListMoreRequested event, Emitter<PagedListState<T>> emit) async {
    if (state case final PagedListLoaded<T> loaded
        when loaded.hasMore && !loaded.loadingMore && loaded.busyId == null) {
      final round = _round;
      emit(
        PagedListLoaded<T>(
          loaded.items,
          query: loaded.query,
          page: loaded.page,
          hasMore: true,
          loadingMore: true,
        ),
      );
      try {
        final next = await read(loaded.page + 1, loaded.query);
        if (round == _round) {
          emit(_loaded(ItemsPage<T>([...loaded.items, ...next.items], page: next.page, totalPages: next.totalPages)));
        }
      } on ApiFailure catch (failure) {
        if (round == _round) {
          emit(
            PagedListLoaded<T>(
              loaded.items,
              query: loaded.query,
              page: loaded.page,
              hasMore: true,
              moreFailure: failure,
            ),
          );
        }
      }
    }
  }

  /// Runs [run] for [item] (one change at a time, and only once the list is shown), then reads the first page again.
  Future<void> change(Emitter<PagedListState<T>> emit, T item, String id, Future<Object?> Function() run) async {
    if (state case final PagedListLoaded<T> loaded when loaded.busyId == null) {
      final round = ++_round;
      emit(
        PagedListLoaded<T>(
          loaded.items,
          query: loaded.query,
          page: loaded.page,
          hasMore: loaded.hasMore,
          busyId: id,
        ),
      );
      ApiFailure? refused;
      try {
        await run();
      } on ApiFailure catch (failure) {
        refused = failure;
      }
      try {
        final page = await read(1, _query);
        if (round == _round) emit(_loaded(page, actionFailure: refused, changed: refused == null ? item : null));
      } on ApiFailure catch (failure) {
        if (round == _round) emit(PagedListFailed<T>(failure));
      }
    }
  }
}
