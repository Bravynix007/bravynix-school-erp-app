import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/notifications/domain/inbox_item.dart';
import 'package:bravynix_school_erp/features/notifications/presentation/bloc/inbox_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/notifications.dart';

void main() {
  late MockNotificationsRepository repository;
  final first = inboxItem();
  final second = inboxItem(id: 'n2', title: 'New diary entry');
  const refused = ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x');

  setUpAll(() => registerFallbackValue(InboxTab.all));
  setUp(() => repository = MockNotificationsRepository());

  InboxBloc build() => InboxBloc(repository, InboxTab.onlyForYou);

  blocTest<InboxBloc, InboxState>(
    'reads the first page of the tab',
    build: () {
      when(() => repository.inbox(InboxTab.all)).thenAnswer((_) async => InboxPage([first], nextCursor: 'c2'));
      return build();
    },
    act: (bloc) => bloc.add(const InboxRequested(InboxTab.all)),
    expect: () => [
      const InboxLoading(InboxTab.all),
      InboxLoaded(InboxTab.all, [first], nextCursor: 'c2'),
    ],
  );

  blocTest<InboxBloc, InboxState>(
    'says why the tab could not be read',
    build: () {
      when(() => repository.inbox(any())).thenThrow(const ApiFailure.network());
      return build();
    },
    act: (bloc) => bloc.add(const InboxRequested(InboxTab.all)),
    expect: () => [const InboxLoading(InboxTab.all), const InboxFailed(InboxTab.all, ApiFailure.network())],
  );

  blocTest<InboxBloc, InboxState>(
    'an answer for the tab left behind is dropped',
    build: () {
      when(() => repository.inbox(InboxTab.all)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return InboxPage([first]);
      });
      when(() => repository.inbox(InboxTab.onlyForYou)).thenAnswer((_) async => InboxPage([second]));
      return build();
    },
    act: (bloc) => bloc
      ..add(const InboxRequested(InboxTab.all))
      ..add(const InboxRequested(InboxTab.onlyForYou)),
    wait: const Duration(milliseconds: 60),
    expect: () => [
      const InboxLoading(InboxTab.all),
      const InboxLoading(InboxTab.onlyForYou),
      InboxLoaded(InboxTab.onlyForYou, [second]),
    ],
  );

  blocTest<InboxBloc, InboxState>(
    'Load more adds the next page after the cursor',
    build: () {
      when(() => repository.inbox(InboxTab.all, cursor: 'c2')).thenAnswer((_) async => InboxPage([second]));
      return build();
    },
    seed: () => InboxLoaded(InboxTab.all, [first], nextCursor: 'c2'),
    act: (bloc) => bloc.add(const InboxMoreRequested()),
    expect: () => [
      InboxLoaded(InboxTab.all, [first], nextCursor: 'c2', loadingMore: true),
      InboxLoaded(InboxTab.all, [first, second]),
    ],
  );

  blocTest<InboxBloc, InboxState>(
    'a failed Load more keeps the pages and says so',
    build: () {
      when(() => repository.inbox(any(), cursor: any(named: 'cursor'))).thenThrow(const ApiFailure.network());
      return build();
    },
    seed: () => InboxLoaded(InboxTab.all, [first], nextCursor: 'c2'),
    act: (bloc) => bloc.add(const InboxMoreRequested()),
    expect: () => [
      InboxLoaded(InboxTab.all, [first], nextCursor: 'c2', loadingMore: true),
      InboxLoaded(InboxTab.all, [first], nextCursor: 'c2', moreFailure: const ApiFailure.network()),
    ],
  );

  blocTest<InboxBloc, InboxState>(
    'Load more at the last page asks for nothing',
    build: build,
    seed: () => InboxLoaded(InboxTab.all, [first]),
    act: (bloc) => bloc.add(const InboxMoreRequested()),
    expect: () => <InboxState>[],
    verify: (_) => verifyNever(() => repository.inbox(any(), cursor: any(named: 'cursor'))),
  );

  blocTest<InboxBloc, InboxState>(
    'opening an unread notice marks it read',
    build: () {
      when(() => repository.markRead('n1')).thenAnswer((_) async => first.asRead());
      return build();
    },
    seed: () => InboxLoaded(InboxTab.all, [first, second]),
    act: (bloc) => bloc.add(const InboxItemOpened('n1')),
    expect: () => [
      InboxLoaded(InboxTab.all, [first.asRead(), second]),
    ],
  );

  blocTest<InboxBloc, InboxState>(
    'opening a notice already read asks for nothing',
    build: build,
    seed: () => InboxLoaded(InboxTab.all, [first.asRead()]),
    act: (bloc) => bloc.add(const InboxItemOpened('n1')),
    expect: () => <InboxState>[],
    verify: (_) => verifyNever(() => repository.markRead(any())),
  );

  blocTest<InboxBloc, InboxState>(
    'a notice that is gone says why it could not be marked, and stays as it was',
    build: () {
      when(() => repository.markRead('n1')).thenThrow(refused);
      return build();
    },
    seed: () => InboxLoaded(InboxTab.all, [first]),
    act: (bloc) => bloc.add(const InboxItemOpened('n1')),
    expect: () => [
      InboxLoaded(InboxTab.all, [first], actionFailure: refused),
    ],
  );

  blocTest<InboxBloc, InboxState>(
    'Mark all read marks the tab, then reads it again',
    build: () {
      when(() => repository.markAllRead(tab: InboxTab.all)).thenAnswer((_) async {});
      when(() => repository.inbox(InboxTab.all)).thenAnswer((_) async => InboxPage([first.asRead(), second.asRead()]));
      return build();
    },
    seed: () => InboxLoaded(InboxTab.all, [first, second]),
    act: (bloc) => bloc.add(const InboxMarkedAllRead()),
    expect: () => [
      InboxLoaded(InboxTab.all, [first, second], working: true),
      InboxLoaded(InboxTab.all, [first.asRead(), second.asRead()]),
    ],
  );

  blocTest<InboxBloc, InboxState>(
    'Clear all deletes the tab, then reads it again and finds it empty',
    build: () {
      when(() => repository.clear(tab: InboxTab.all)).thenAnswer((_) async {});
      when(() => repository.inbox(InboxTab.all)).thenAnswer((_) async => const InboxPage([]));
      return build();
    },
    seed: () => InboxLoaded(InboxTab.all, [first]),
    act: (bloc) => bloc.add(const InboxCleared()),
    expect: () => [
      InboxLoaded(InboxTab.all, [first], working: true),
      const InboxLoaded(InboxTab.all, []),
    ],
  );

  blocTest<InboxBloc, InboxState>(
    'a refused change says why and shows what the tab holds now',
    build: () {
      when(() => repository.clear(tab: InboxTab.all)).thenThrow(const ApiFailure.network());
      when(() => repository.inbox(InboxTab.all)).thenAnswer((_) async => InboxPage([first]));
      return build();
    },
    seed: () => InboxLoaded(InboxTab.all, [first]),
    act: (bloc) => bloc.add(const InboxCleared()),
    expect: () => [
      InboxLoaded(InboxTab.all, [first], working: true),
      InboxLoaded(InboxTab.all, [first], actionFailure: const ApiFailure.network()),
    ],
  );

  blocTest<InboxBloc, InboxState>(
    'a second Load more while one is on its way asks for nothing',
    build: () {
      when(() => repository.inbox(InboxTab.all, cursor: 'c2')).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return InboxPage([second]);
      });
      return build();
    },
    seed: () => InboxLoaded(InboxTab.all, [first], nextCursor: 'c2'),
    act: (bloc) => bloc
      ..add(const InboxMoreRequested())
      ..add(const InboxMoreRequested()),
    wait: const Duration(milliseconds: 50),
    expect: () => [
      InboxLoaded(InboxTab.all, [first], nextCursor: 'c2', loadingMore: true),
      InboxLoaded(InboxTab.all, [first, second]),
    ],
    verify: (_) => verify(() => repository.inbox(InboxTab.all, cursor: 'c2')).called(1),
  );

  blocTest<InboxBloc, InboxState>(
    'a page that was on its way when Mark all read started does not land on the list read again',
    build: () {
      when(() => repository.inbox(InboxTab.all, cursor: 'c2')).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return InboxPage([second]);
      });
      when(() => repository.markAllRead(tab: InboxTab.all)).thenAnswer((_) async {});
      when(() => repository.inbox(InboxTab.all)).thenAnswer((_) async => InboxPage([first.asRead()]));
      return build();
    },
    seed: () => InboxLoaded(InboxTab.all, [first], nextCursor: 'c2'),
    act: (bloc) async {
      bloc.add(const InboxMoreRequested());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const InboxMarkedAllRead());
    },
    wait: const Duration(milliseconds: 60),
    verify: (bloc) => expect(bloc.state, InboxLoaded(InboxTab.all, [first.asRead()])),
  );

  blocTest<InboxBloc, InboxState>(
    'Mark all read while one is running asks once',
    build: () {
      when(() => repository.markAllRead(tab: InboxTab.all)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      when(() => repository.inbox(InboxTab.all)).thenAnswer((_) async => InboxPage([first.asRead()]));
      return build();
    },
    seed: () => InboxLoaded(InboxTab.all, [first]),
    act: (bloc) => bloc
      ..add(const InboxMarkedAllRead())
      ..add(const InboxMarkedAllRead()),
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => repository.markAllRead(tab: InboxTab.all)).called(1),
  );

  blocTest<InboxBloc, InboxState>(
    'Clear while one is running asks once',
    build: () {
      when(() => repository.clear(tab: InboxTab.all)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      when(() => repository.inbox(InboxTab.all)).thenAnswer((_) async => const InboxPage([]));
      return build();
    },
    seed: () => InboxLoaded(InboxTab.all, [first]),
    act: (bloc) => bloc
      ..add(const InboxCleared())
      ..add(const InboxCleared()),
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => repository.clear(tab: InboxTab.all)).called(1),
  );
}
