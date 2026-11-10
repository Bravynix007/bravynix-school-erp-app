import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:flutter_test/flutter_test.dart';

const _failure = ApiFailure(statusCode: 500, code: 'INTERNAL_ERROR', message: 'x');
const _refused = ApiFailure(statusCode: 409, code: 'CANNOT_ACT_ON_SELF', message: 'x');

final class _Remove extends PagedListEvent {
  const new(this.item);

  final String item;

  @override
  List<Object?> get props => [item];
}

/// Three pages of two items: a1 a2, b1 b2, c1 c2. A search keeps the items that contain it, on one page.
class _Bloc extends PagedListBloc<String> {
  new() {
    on<_Remove>((event, emit) => change(emit, event.item, event.item, () async => removed.add(event.item)));
  }

  final List<String> removed = [];
  final List<(int, String)> asked = [];

  /// Answers a read for a page and a search when it is completed, so a test decides which answer comes first.
  final Map<(int, String), Completer<ItemsPage<String>>> gates = {};
  ApiFailure? failing;

  static const _all = ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'];

  @override
  Future<ItemsPage<String>> read(int page, String query) async {
    asked.add((page, query));
    if (gates[(page, query)] case final gate?) return await gate.future;
    if (failing != null) throw failing!;
    if (query.isNotEmpty) {
      return ItemsPage(
        [
          for (final item in _all)
            if (item.contains(query) && !removed.contains(item)) item,
        ],
        page: 1,
        totalPages: 1,
      );
    }
    final rest = [
      for (final item in _all)
        if (!removed.contains(item)) item,
    ];
    final from = (page - 1) * 2;
    return ItemsPage(rest.skip(from).take(2).toList(), page: page, totalPages: (rest.length / 2).ceil());
  }
}

void main() {
  blocTest<_Bloc, PagedListState<String>>(
    'reads the first page',
    build: _Bloc.new,
    act: (bloc) => bloc.add(const PagedListRequested()),
    expect: () => [
      const PagedListLoading<String>(),
      const PagedListLoaded<String>(['a1', 'a2'], hasMore: true),
    ],
  );

  blocTest<_Bloc, PagedListState<String>>(
    'fails with the reason, and reads again on Try again',
    build: _Bloc.new,
    act: (bloc) async {
      bloc
        ..failing = _failure
        ..add(const PagedListRequested());
      await Future<void>.delayed(Duration.zero);
      bloc
        ..failing = null
        ..add(const PagedListRequested());
    },
    expect: () => [
      const PagedListLoading<String>(),
      const PagedListFailed<String>(_failure),
      const PagedListLoading<String>(),
      const PagedListLoaded<String>(['a1', 'a2'], hasMore: true),
    ],
  );

  blocTest<_Bloc, PagedListState<String>>(
    'adds the next page to the ones read, until there is none',
    build: _Bloc.new,
    act: (bloc) async {
      bloc.add(const PagedListRequested());
      await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
      bloc.add(const PagedListMoreRequested());
      await bloc.stream.firstWhere(
        (state) => state is PagedListLoaded<String> && !state.loadingMore && state.page == 2,
      );
      bloc
        ..add(const PagedListMoreRequested())
        ..add(const PagedListMoreRequested());
    },
    skip: 2,
    expect: () => [
      const PagedListLoaded<String>(['a1', 'a2'], hasMore: true, loadingMore: true),
      const PagedListLoaded<String>(['a1', 'a2', 'b1', 'b2'], page: 2, hasMore: true),
      const PagedListLoaded<String>(['a1', 'a2', 'b1', 'b2'], page: 2, hasMore: true, loadingMore: true),
      const PagedListLoaded<String>(['a1', 'a2', 'b1', 'b2', 'c1', 'c2'], page: 3),
    ],
    // A second ask while one is on its way, and one after the last page, read nothing.
    verify: (bloc) => expect(bloc.asked, [(1, ''), (2, ''), (3, '')]),
  );

  blocTest<_Bloc, PagedListState<String>>(
    'keeps the pages when Load more fails, and tries the same page again',
    build: _Bloc.new,
    act: (bloc) async {
      bloc.add(const PagedListRequested());
      await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
      bloc
        ..failing = _failure
        ..add(const PagedListMoreRequested());
      await bloc.stream.firstWhere((state) => state is PagedListLoaded<String> && state.moreFailure != null);
      bloc
        ..failing = null
        ..add(const PagedListMoreRequested());
    },
    skip: 2,
    expect: () => [
      const PagedListLoaded<String>(['a1', 'a2'], hasMore: true, loadingMore: true),
      const PagedListLoaded<String>(['a1', 'a2'], hasMore: true, moreFailure: _failure),
      const PagedListLoaded<String>(['a1', 'a2'], hasMore: true, loadingMore: true),
      const PagedListLoaded<String>(['a1', 'a2', 'b1', 'b2'], page: 2, hasMore: true),
    ],
  );

  blocTest<_Bloc, PagedListState<String>>(
    'searches from the first page, and clears the search',
    build: _Bloc.new,
    act: (bloc) async {
      bloc.add(const PagedListRequested());
      await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
      bloc.add(const PagedListSearched(' b1 '));
      await bloc.stream.firstWhere((state) => state is PagedListLoaded<String> && state.query == 'b1');
      bloc.add(const PagedListSearched(''));
    },
    skip: 2,
    expect: () => [
      const PagedListLoading<String>(),
      const PagedListLoaded<String>(['b1'], query: 'b1'),
      const PagedListLoading<String>(),
      const PagedListLoaded<String>(['a1', 'a2'], hasMore: true),
    ],
    verify: (bloc) => expect(bloc.asked, [(1, ''), (1, 'b1'), (1, '')]),
  );

  blocTest<_Bloc, PagedListState<String>>(
    'does not search for one letter, or for what it already shows',
    build: _Bloc.new,
    act: (bloc) async {
      bloc.add(const PagedListRequested());
      await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
      bloc
        ..add(const PagedListSearched('b'))
        ..add(const PagedListSearched(''))
        ..add(const PagedListSearched('  '));
    },
    skip: 2,
    expect: () => <PagedListState<String>>[],
    verify: (bloc) => expect(bloc.asked, [(1, '')]),
  );

  blocTest<_Bloc, PagedListState<String>>(
    'drops the answer to an earlier search when a later one was asked for',
    build: _Bloc.new,
    act: (bloc) async {
      final slow = bloc.gates[(1, 'a1')] = Completer();
      bloc.add(const PagedListSearched('a1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const PagedListSearched('c1'));
      await Future<void>.delayed(Duration.zero);
      slow.complete(const ItemsPage(['a1'], page: 1, totalPages: 1));
    },
    expect: () => [
      const PagedListLoading<String>(),
      const PagedListLoaded<String>(['c1'], query: 'c1'),
    ],
  );

  blocTest<_Bloc, PagedListState<String>>(
    'drops the answer to Load more when the list was asked for again meanwhile',
    build: _Bloc.new,
    act: (bloc) async {
      bloc.add(const PagedListRequested());
      await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
      final slow = bloc.gates[(2, '')] = Completer();
      bloc.add(const PagedListMoreRequested());
      await Future<void>.delayed(Duration.zero);
      final earlier = bloc.gates[(1, 'c1')] = Completer();
      bloc
        ..add(const PagedListSearched('c1'))
        ..add(const PagedListSearched('c2'));
      await bloc.stream.firstWhere((state) => state is PagedListLoaded<String> && state.query == 'c2');
      slow.complete(const ItemsPage(['b1', 'b2'], page: 2, totalPages: 3));
      earlier.complete(const ItemsPage(['c1'], page: 1, totalPages: 1));
      await Future<void>.delayed(Duration.zero);
    },
    skip: 2,
    expect: () => [
      const PagedListLoaded<String>(['a1', 'a2'], hasMore: true, loadingMore: true),
      const PagedListLoading<String>(),
      const PagedListLoaded<String>(['c2'], query: 'c2'),
    ],
  );

  blocTest<_Bloc, PagedListState<String>>(
    'runs a change for one item, then reads the first page again and says which item went',
    build: _Bloc.new,
    act: (bloc) async {
      bloc.add(const PagedListRequested());
      await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
      bloc.add(const _Remove('a1'));
    },
    skip: 2,
    expect: () => [
      const PagedListLoaded<String>(['a1', 'a2'], hasMore: true, busyId: 'a1'),
      const PagedListLoaded<String>(['a2', 'b1'], hasMore: true, changed: 'a1'),
    ],
  );

  test('reads nothing more for a Load more asked while one is on its way', () async {
    final bloc = _Bloc();
    addTearDown(bloc.close);
    bloc.add(const PagedListRequested());
    await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
    final gate = bloc.gates[(2, '')] = Completer();
    bloc
      ..add(const PagedListMoreRequested())
      ..add(const PagedListMoreRequested());
    await Future<void>.delayed(Duration.zero);
    gate.complete(const ItemsPage(['b1', 'b2'], page: 2, totalPages: 3));
    await bloc.stream.firstWhere((state) => state is PagedListLoaded<String> && state.page == 2);
    expect(bloc.asked.where((ask) => ask.$1 == 2), hasLength(1));
  });

  test('drops the failure of a Load more asked before a new search, and keeps the search list', () async {
    final bloc = _Bloc();
    addTearDown(bloc.close);
    bloc.add(const PagedListRequested());
    await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
    final late = bloc.gates[(2, '')] = Completer();
    bloc.add(const PagedListMoreRequested());
    await Future<void>.delayed(Duration.zero);
    bloc.add(const PagedListSearched('c2'));
    await bloc.stream.firstWhere((state) => state is PagedListLoaded<String> && state.query == 'c2');
    final seen = <PagedListState<String>>[];
    final listening = bloc.stream.listen(seen.add);
    addTearDown(listening.cancel);
    late.completeError(_failure);
    await Future<void>.delayed(Duration.zero);
    expect(seen, isEmpty);
    expect(bloc.state, const PagedListLoaded<String>(['c2'], query: 'c2'));
  });

  test('reads the first page of the same search again after a change', () async {
    final bloc = _Bloc();
    addTearDown(bloc.close);
    bloc.add(const PagedListSearched('a1'));
    await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
    bloc.add(const _Remove('a1'));
    final state = await bloc.stream.firstWhere((state) => state is PagedListLoaded<String> && state.busyId == null);
    expect(state, const PagedListLoaded<String>([], query: 'a1', changed: 'a1'));
    expect(bloc.asked.last, (1, 'a1'));
  });

  test('runs a change asked while Load more is on its way, and drops the page that comes after', () async {
    final bloc = _Bloc();
    addTearDown(bloc.close);
    bloc.add(const PagedListRequested());
    await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
    final late = bloc.gates[(2, '')] = Completer();
    bloc.add(const PagedListMoreRequested());
    await Future<void>.delayed(Duration.zero);
    bloc.add(const _Remove('a1'));
    final done = await bloc.stream.firstWhere((state) => state is PagedListLoaded<String> && state.changed != null);
    expect(bloc.removed, ['a1']);
    late.complete(const ItemsPage(['b1', 'b2'], page: 2, totalPages: 3));
    await Future<void>.delayed(Duration.zero);
    expect(done, const PagedListLoaded<String>(['a2', 'b1'], hasMore: true, changed: 'a1'));
    expect(bloc.state, done);
  });

  test('ignores a search while a change is going, so the outcome of the change is not lost', () async {
    final bloc = _RefusingBloc();
    addTearDown(bloc.close);
    bloc.add(const PagedListRequested());
    await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
    final gate = bloc.gates[(1, '')] = Completer();
    bloc
      ..add(const _Refuse('a1'))
      ..add(const PagedListSearched('b1'));
    await Future<void>.delayed(Duration.zero);
    gate.complete(const ItemsPage(['a1', 'a2'], page: 1, totalPages: 3));
    final state = await bloc.stream.firstWhere((state) => state is PagedListLoaded<String> && state.busyId == null);
    expect(state, const PagedListLoaded<String>(['a1', 'a2'], hasMore: true, actionFailure: _refused));
    expect(bloc.asked, isNot(contains((1, 'b1'))));
  });

  test('a refused change keeps its reason with the list read again', () async {
    final bloc = _RefusingBloc();
    addTearDown(bloc.close);
    bloc.add(const PagedListRequested());
    await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
    bloc.add(const _Refuse('a1'));
    final state = await bloc.stream.firstWhere((state) => state is PagedListLoaded<String> && state.busyId == null);
    expect(state, const PagedListLoaded<String>(['a1', 'a2'], hasMore: true, actionFailure: _refused));
  });

  test('ignores a change while one is going, and Load more while it goes', () async {
    final bloc = _Bloc();
    addTearDown(bloc.close);
    bloc.add(const PagedListRequested());
    await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
    final gate = bloc.gates[(1, '')] = Completer();
    bloc
      ..add(const _Remove('a1'))
      ..add(const _Remove('a2'))
      ..add(const PagedListMoreRequested());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.removed, ['a1']);
    gate.complete(const ItemsPage(['a2'], page: 1, totalPages: 1));
    await bloc.stream.firstWhere((state) => state is PagedListLoaded<String> && state.busyId == null);
    expect(bloc.asked.where((ask) => ask.$1 == 2), isEmpty);
  });

  test('fails when the list cannot be read again after a change', () async {
    final bloc = _Bloc();
    addTearDown(bloc.close);
    bloc.add(const PagedListRequested());
    await bloc.stream.firstWhere((state) => state is PagedListLoaded<String>);
    bloc
      ..failing = _failure
      ..add(const _Remove('a1'));
    expect(
      await bloc.stream.firstWhere((state) => state is PagedListFailed<String>),
      const PagedListFailed<String>(_failure),
    );
  });
}

/// A bloc whose change is refused.
class _RefusingBloc extends _Bloc {
  new() {
    on<_Refuse>((event, emit) => change(emit, event.item, event.item, () async => throw _refused));
  }
}

final class _Refuse extends PagedListEvent {
  const new(this.item);

  final String item;

  @override
  List<Object?> get props => [item];
}
