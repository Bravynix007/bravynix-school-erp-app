import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/features/notifications/presentation/bloc/unread_count_bloc.dart';
import 'package:bravynix_school_erp/features/notifications/presentation/view/notification_bell_button.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockUnreadCountBloc extends MockBloc<UnreadCountEvent, int> implements UnreadCountBloc;

void main() {
  late _MockUnreadCountBloc bloc;
  setUpAll(() => registerFallbackValue(const UnreadCountRequested()));
  setUp(() => bloc = _MockUnreadCountBloc());

  testWidgets('shows the unread count and names it for a screen reader', (tester) async {
    when(() => bloc.state).thenReturn(12);
    await tester.pumpApp(
      Scaffold(
        body: BlocProvider<UnreadCountBloc>.value(value: bloc, child: const NotificationBellView()),
      ),
    );
    expect(find.text('9+'), findsOneWidget);
    expect(find.bySemanticsLabel('Notifications, 12 unread'), findsOneWidget);
  });

  testWidgets('opens the inbox, and reads the count again on the way back', (tester) async {
    when(() => bloc.state).thenReturn(0);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: BlocProvider<UnreadCountBloc>.value(value: bloc, child: const NotificationBellView()),
          ),
        ),
        GoRoute(
          path: '/inbox',
          builder: (context, _) => Scaffold(
            body: TextButton(onPressed: context.pop, child: const Text('back')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.tap(find.byKey(const Key('home.bell')));
    await tester.pumpAndSettle();
    expect(find.text('back'), findsOneWidget);
    verifyNever(() => bloc.add(const UnreadCountRequested()));

    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const UnreadCountRequested())).called(1);
  });
}
