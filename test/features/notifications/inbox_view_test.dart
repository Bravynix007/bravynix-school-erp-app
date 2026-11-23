import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/notifications/domain/inbox_item.dart';
import 'package:bravynix_school_erp/features/notifications/presentation/bloc/inbox_bloc.dart';
import 'package:bravynix_school_erp/features/notifications/presentation/view/inbox_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/notifications.dart';
import '../../helpers/pump_app.dart';

class _MockInboxBloc extends MockBloc<InboxEvent, InboxState> implements InboxBloc;

void main() {
  late _MockInboxBloc bloc;
  final unread = inboxItem();
  final read = inboxItem(id: 'n2', title: 'New diary entry', body: '', isRead: true, sender: null);
  const parentTabs = [InboxTab.onlyForYou, InboxTab.all, InboxTab.allStudents];

  setUpAll(() => registerFallbackValue(const InboxMoreRequested()));
  setUp(() => bloc = _MockInboxBloc());

  Future<void> pump(WidgetTester tester, InboxState state, {double textScale = 1, List<InboxTab> tabs = parentTabs}) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<InboxBloc>.value(
        value: bloc,
        child: InboxView(tabs: tabs),
      ),
      textScale: textScale,
    );
  }

  testWidgets('lists the notices with who sent them and when, and marks the unread ones', (tester) async {
    await pump(tester, InboxLoaded(InboxTab.onlyForYou, [unread, read]));
    expect(find.text('Diya is absent today'), findsOneWidget);
    expect(find.text('From: Green Valley School · 17-11-2026 10:15'), findsOneWidget);
    expect(find.text('17-11-2026 10:15'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Unread')), findsOneWidget);
  });

  testWidgets('a tap on a notice opens it', (tester) async {
    await pump(tester, InboxLoaded(InboxTab.onlyForYou, [unread]));
    await tester.tap(find.byKey(const ValueKey('inbox.item.n1')));
    verify(() => bloc.add(const InboxItemOpened('n1'))).called(1);
  });

  testWidgets('shows the tabs of the role and asks for the one chosen', (tester) async {
    await pump(tester, InboxLoaded(InboxTab.onlyForYou, [unread]));
    expect(find.text('All students'), findsOneWidget);
    expect(find.text('All teachers'), findsNothing);
    await tester.ensureVisible(find.text('All students'));
    await tester.tap(find.text('All students'));
    verify(() => bloc.add(const InboxRequested(InboxTab.allStudents))).called(1);
  });

  testWidgets('Mark all read marks the tab', (tester) async {
    await pump(tester, InboxLoaded(InboxTab.onlyForYou, [unread]));
    await tester.tap(find.byKey(const Key('inbox.markAllRead')));
    verify(() => bloc.add(const InboxMarkedAllRead())).called(1);
  });

  testWidgets('Mark all read is not offered when everything is read', (tester) async {
    await pump(tester, InboxLoaded(InboxTab.onlyForYou, [read]));
    expect(tester.widget<IconButton>(find.byKey(const Key('inbox.markAllRead'))).onPressed, isNull);
  });

  testWidgets('Clear all asks first, and clears only once confirmed', (tester) async {
    await pump(tester, InboxLoaded(InboxTab.all, [unread]));
    await tester.tap(find.byKey(const Key('inbox.clear')));
    await tester.pumpAndSettle();
    expect(find.text('Every notification in "All" is deleted for good.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(const InboxCleared()));

    await tester.tap(find.byKey(const Key('inbox.clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const InboxCleared())).called(1);
  });

  testWidgets('both change buttons wait while a change is on its way', (tester) async {
    await pump(tester, InboxLoaded(InboxTab.all, [unread], working: true));
    expect(tester.widget<IconButton>(find.byKey(const Key('inbox.markAllRead'))).onPressed, isNull);
    expect(tester.widget<IconButton>(find.byKey(const Key('inbox.clear'))).onPressed, isNull);
  });

  testWidgets('there is nothing to clear in an empty tab', (tester) async {
    await pump(tester, const InboxLoaded(InboxTab.all, []));
    expect(tester.widget<IconButton>(find.byKey(const Key('inbox.clear'))).onPressed, isNull);
  });

  testWidgets('Load more asks for the next page', (tester) async {
    await pump(tester, InboxLoaded(InboxTab.all, [unread], nextCursor: 'c2'));
    await tester.tap(find.byKey(const Key('inbox.more')));
    verify(() => bloc.add(const InboxMoreRequested())).called(1);
  });

  testWidgets('says why Load more failed and offers Try again', (tester) async {
    await pump(
      tester,
      InboxLoaded(InboxTab.all, [unread], nextCursor: 'c2', moreFailure: const ApiFailure.network()),
    );
    expect(find.byKey(const Key('inbox.moreFailed')), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('says why a change was refused above the list', (tester) async {
    await pump(tester, InboxLoaded(InboxTab.all, [unread], actionFailure: const ApiFailure.network()));
    expect(find.byKey(const Key('inbox.actionFailed')), findsOneWidget);
  });

  testWidgets('an empty tab says so', (tester) async {
    await pump(tester, const InboxLoaded(InboxTab.all, []));
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const InboxLoading(InboxTab.all));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and reads the tab again on Try again', (tester) async {
    await pump(tester, const InboxFailed(InboxTab.all, ApiFailure.network()));
    expect(find.byKey(const Key('inbox.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const InboxRequested(InboxTab.all))).called(1);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    final long = inboxItem(
      id: 'n3',
      title: 'Lakshmi Priyadarshini Venkataramanaswamy is absent today',
      body: 'Lakshmi Priyadarshini was marked Absent in 10th - B on 17-11-2026, at Sri Vidya Senior Secondary School.',
      sender: 'Sri Vidya Educational Society Senior Secondary School',
    );
    await pump(tester, InboxLoaded(InboxTab.onlyForYou, [long, read], nextCursor: 'c2'), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
