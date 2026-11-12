import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/paged_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';

class _MockBloc extends MockBloc<PagedListEvent, PagedListState<String>> implements PagedListBloc<String>;

typedef _Loaded = PagedListLoaded<String>;

const _down = ApiFailure(statusCode: 503, code: 'UNAVAILABLE', message: 'x');

void main() {
  late _MockBloc bloc;
  var retried = 0;
  final idles = <bool>[];
  final lockedCards = <String>[];

  setUpAll(() {
    registerFallbackValue(const PagedListRequested());
  });
  setUp(() {
    bloc = _MockBloc();
    retried = 0;
    idles.clear();
    lockedCards.clear();
  });

  Future<void> pump(
    WidgetTester tester,
    PagedListState<String> state, {
    double textScale = 1,
    Size size = const Size(400, 1200),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      Scaffold(
        body: PagedListView<String>(
          bloc: bloc,
          keyPrefix: 'things',
          searchHint: 'Search things',
          searchClearTooltip: 'Clear search',
          loadMoreLabel: 'Load more things',
          errorText: (failure) => 'Said: ${failure.code}',
          onRetry: () => retried++,
          belowSearch: (context, {required idle}) {
            idles.add(idle);
            return const Text('below the search');
          },
          empty: (context, query) => Text(query.isEmpty ? 'nothing yet' : 'nothing for "$query"'),
          leading: (context, {required idle}) => [Text(idle ? 'leading idle' : 'leading busy')],
          idOf: (item) => item,
          itemBuilder: (context, item, {required busy, required locked}) {
            if (locked) lockedCards.add(item);
            return Text(busy ? '$item (busy)' : item);
          },
          changedMessage: (item) => '$item changed',
        ),
      ),
      textScale: textScale,
      size: size,
    );
  }

  testWidgets('lists the items under what leads them, and what is under the search', (tester) async {
    await pump(tester, const _Loaded(['Asha', 'Bala']));
    expect(find.text('below the search'), findsOneWidget);
    expect(find.text('leading idle'), findsOneWidget);
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Bala'), findsOneWidget);
    expect(idles.last, isTrue);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const PagedListLoading<String>());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and tries again', (tester) async {
    await pump(tester, const PagedListFailed<String>(_down));
    expect(find.byKey(const Key('things.failed')), findsOneWidget);
    expect(find.text('Said: UNAVAILABLE'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });

  testWidgets('says there is no access, with no retry', (tester) async {
    await pump(tester, const PagedListFailed<String>(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
    expect(find.byKey(const Key('things.forbidden')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  group('an empty list', () {
    testWidgets("is the screen's own, for no search", (tester) async {
      await pump(tester, const _Loaded([]));
      expect(find.text('nothing yet'), findsOneWidget);
      expect(find.text('leading idle'), findsNothing);
    });

    testWidgets('is told the search that found no one', (tester) async {
      await pump(tester, const _Loaded([], query: 'zzz'));
      expect(find.text('nothing for "zzz"'), findsOneWidget);
    });
  });

  group('while a change is on its way', () {
    testWidgets('marks the card it is for, locks the others, and the search, and what leads and what is below', (
      tester,
    ) async {
      await pump(tester, const _Loaded(['Asha', 'Bala'], busyId: 'Bala'));
      expect(find.text('Bala (busy)'), findsOneWidget);
      expect(find.text('Asha'), findsOneWidget);
      expect(lockedCards, containsAll(['Asha', 'Bala']));
      expect(find.text('leading busy'), findsOneWidget);
      expect(idles.last, isFalse);
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: find.byKey(const Key('things.search')), matching: find.byType(TextField)),
            )
            .enabled,
        isFalse,
      );
    });

    testWidgets('says why the change was refused, above the list', (tester) async {
      await pump(tester, const _Loaded(['Asha'], actionFailure: _down));
      expect(
        find.descendant(of: find.byKey(const Key('things.actionFailed')), matching: find.text('Said: UNAVAILABLE')),
        findsOneWidget,
      );
    });

    testWidgets('says which item it went through for', (tester) async {
      whenListen(
        bloc,
        Stream.value(const _Loaded(['Bala'], changed: 'Asha')),
        initialState: const _Loaded(['Asha', 'Bala'], busyId: 'Asha'),
      );
      await tester.pumpAppScaled(
        Scaffold(
          body: PagedListView<String>(
            bloc: bloc,
            keyPrefix: 'things',
            searchHint: 'Search things',
            searchClearTooltip: 'Clear search',
            loadMoreLabel: 'Load more things',
            errorText: (failure) => failure.code,
            onRetry: () {},
            empty: (context, query) => const Text('nothing yet'),
            idOf: (item) => item,
            itemBuilder: (context, item, {required busy, required locked}) => Text(item),
            changedMessage: (item) => '$item changed',
          ),
        ),
        size: const Size(400, 1200),
      );
      await tester.pump();
      expect(find.text('Asha changed'), findsOneWidget);
    });
  });

  group('the search', () {
    testWidgets("is sent on the keyboard's search key, and cleared as soon as the box is emptied", (tester) async {
      await pump(tester, const _Loaded(['Asha']));
      await tester.enterText(find.byKey(const Key('things.search')), 'ash');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      verify(() => bloc.add(const PagedListSearched('ash'))).called(1);
      await tester.enterText(find.byKey(const Key('things.search')), '');
      verify(() => bloc.add(const PagedListSearched(''))).called(1);
    });

    testWidgets('is cut at 100 letters, which is all the API takes', (tester) async {
      await pump(tester, const _Loaded(['Asha']));
      await tester.enterText(find.byKey(const Key('things.search')), 'k' * 101);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      verify(() => bloc.add(PagedListSearched('k' * 100))).called(1);
    });
  });

  group('Load more', () {
    testWidgets('is offered while there is another page, and asks for it', (tester) async {
      await pump(tester, const _Loaded(['Asha'], hasMore: true));
      await tester.tap(find.text('Load more things'));
      verify(() => bloc.add(const PagedListMoreRequested())).called(1);
    });

    testWidgets('is not offered on the last page', (tester) async {
      await pump(tester, const _Loaded(['Asha']));
      expect(find.byKey(const Key('things.more')), findsNothing);
    });

    testWidgets('says why it failed, and offers Try again', (tester) async {
      await pump(tester, const _Loaded(['Asha'], hasMore: true, moreFailure: _down));
      expect(find.byKey(const Key('things.moreFailed')), findsOneWidget);
      expect(find.text('Load more things'), findsNothing);
      await tester.tap(find.byKey(const Key('things.more')));
      verify(() => bloc.add(const PagedListMoreRequested())).called(1);
    });

    testWidgets('waits while a change is on its way', (tester) async {
      await pump(tester, const _Loaded(['Asha'], hasMore: true, busyId: 'Asha'));
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.descendant(
                of: find.byKey(const Key('things.more')),
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
              ),
            )
            .onPressed,
        isNull,
      );
    });
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(
      tester,
      const _Loaded(['Asha', 'Bala'], hasMore: true, moreFailure: _down),
      textScale: 2,
      size: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
