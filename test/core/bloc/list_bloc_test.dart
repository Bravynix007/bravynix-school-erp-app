import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Notice { removed }

final class _Remove extends ListEvent {
  const new(this.item);

  final String item;

  @override
  List<Object?> get props => [item];
}

/// A list of strings read from [source], and one change: remove an item.
class _Bloc extends ListBloc<String> {
  new(this.source, {this.removing}) {
    on<_Remove>(
      (event, emit) => change(emit, event.item, event.item, () async {
        await removing?.call(event.item);
        source.remove(event.item);
        return null;
      }, notice: _Notice.removed),
    );
  }

  final List<String> source;
  final Future<void> Function(String item)? removing;
  Object? readFailure;

  @override
  Future<List<String>> read() async {
    if (readFailure case final ApiFailure failure) throw failure;
    return List.of(source);
  }
}

const _refused = ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x');

void main() {
  blocTest<_Bloc, ListState<String>>(
    'loads the items',
    build: () => _Bloc(['a', 'b']),
    act: (bloc) => bloc.add(const ListRequested()),
    expect: () => [
      const ListLoading<String>(),
      const ListLoaded<String>(['a', 'b']),
    ],
  );

  blocTest<_Bloc, ListState<String>>(
    'keeps the failure for the screen, and loads again on retry',
    build: () => _Bloc(['a'])..readFailure = const ApiFailure.network(),
    act: (bloc) async {
      bloc.add(const ListRequested());
      await bloc.stream.firstWhere((state) => state is ListFailed<String>);
      bloc
        ..readFailure = null
        ..add(const ListRequested());
    },
    expect: () => [
      const ListLoading<String>(),
      const ListFailed<String>(ApiFailure.network()),
      const ListLoading<String>(),
      const ListLoaded<String>(['a']),
    ],
  );

  blocTest<_Bloc, ListState<String>>(
    'runs a change for one item, then reads the list again, saying which item and what kind',
    build: () => _Bloc(['a', 'b']),
    act: (bloc) async {
      bloc.add(const ListRequested());
      await bloc.stream.firstWhere((state) => state is ListLoaded<String>);
      bloc.add(const _Remove('a'));
    },
    skip: 2,
    expect: () => [
      const ListLoaded<String>(['a', 'b'], busyId: 'a'),
      const ListLoaded<String>(['b'], changed: 'a', notice: _Notice.removed),
    ],
  );

  blocTest<_Bloc, ListState<String>>(
    'says why a change was refused, with the list read again',
    build: () => _Bloc(['a'], removing: (_) async => throw _refused),
    act: (bloc) async {
      bloc.add(const ListRequested());
      await bloc.stream.firstWhere((state) => state is ListLoaded<String>);
      bloc.add(const _Remove('a'));
    },
    skip: 2,
    expect: () => [
      const ListLoaded<String>(['a'], busyId: 'a'),
      const ListLoaded<String>(['a'], actionFailure: _refused),
    ],
  );

  blocTest<_Bloc, ListState<String>>(
    'fails the screen when the list cannot be read again after a change',
    build: () => _Bloc(['a'], removing: (_) async {}),
    act: (bloc) async {
      bloc.add(const ListRequested());
      await bloc.stream.firstWhere((state) => state is ListLoaded<String>);
      bloc
        ..readFailure = const ApiFailure.network()
        ..add(const _Remove('a'));
    },
    skip: 2,
    expect: () => [
      const ListLoaded<String>(['a'], busyId: 'a'),
      const ListFailed<String>(ApiFailure.network()),
    ],
  );

  test('does not start a second change while one is on its way', () async {
    final bloc = _Bloc(['a', 'b'], removing: (_) => Future<void>.delayed(const Duration(milliseconds: 10)));
    addTearDown(bloc.close);
    bloc.add(const ListRequested());
    await bloc.stream.firstWhere((state) => state is ListLoaded<String>);
    bloc
      ..add(const _Remove('a'))
      ..add(const _Remove('b'));
    await bloc.stream.firstWhere((state) => state is ListLoaded<String> && state.changed != null);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(bloc.source, ['b']);
  });

  blocTest<_Bloc, ListState<String>>(
    'ignores a change before the list is shown',
    build: () => _Bloc(['a']),
    act: (bloc) => bloc.add(const _Remove('a')),
    expect: () => <ListState<String>>[],
    verify: (bloc) => expect(bloc.source, ['a']),
  );
}
