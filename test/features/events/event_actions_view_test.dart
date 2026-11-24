import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/domain/events_repository.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/event_bloc.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/events_bloc.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_form_page.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_page.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/events_page.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/events.dart';
import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/network_images.dart';
import '../../helpers/pump_app.dart';

class _MockActiveChildBloc extends MockBloc<ActiveChildEvent, ActiveChildState> implements ActiveChildBloc;

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

ApiFailure refusal(String code, {int status = 403}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words');

void main() {
  late MockEventsRepository repository;
  setUp(() {
    repository = MockEventsRepository();
    when(
      () => repository.events(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => []);
  });

  group('the event', () {
    final editable = schoolEvent(canEdit: true);
    setUpAll(() {
      registerFallbackValue(editable);
      registerFallbackValue(EventScope.society);
    });

    /// Opens the event from a list, so that what it closes with and the form it opens can be seen.
    Future<({List<bool?> closed, List<Object?> forms})> pump(
      WidgetTester tester,
      SchoolEvent event, {
      bool owner = false,
    }) async {
      when(() => repository.event('e1')).thenAnswer((_) async => event);
      final closed = <bool?>[];
      final forms = <Object?>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () async => closed.add(await context.push<bool>('/event')),
                child: const Text('open'),
              ),
            ),
          ),
          GoRoute(
            path: '/event',
            builder: (_, _) => BlocProvider(
              create: (_) => EventBloc(repository, 'e1')..add(const EventRequested()),
              child: EventView(owner: owner),
            ),
          ),
          GoRoute(
            path: AppRoutes.eventForm,
            builder: (context, state) {
              forms.add(state.extra);
              return Scaffold(
                body: TextButton(onPressed: () => context.pop(true), child: const Text('form saved')),
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpAppScaled(
        Router(
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
        ),
        size: const Size(400, 1000),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return (closed: closed, forms: forms);
    }

    testWidgets('shows the picture the event has, from its public address', (tester) async {
      final withImage = schoolEvent(
        image: const EventImage(id: 'f1', url: 'https://files.test/public/f1'),
      );
      await withNetworkImages(() async {
        await pump(tester, withImage);
        expect(find.byKey(const Key('event.image')), findsOneWidget);
        expect(find.bySemanticsLabel('Picture of the event'), findsOneWidget);
      });
    });

    testWidgets('has no picture to show for an event without one', (tester) async {
      await pump(tester, schoolEvent());
      expect(find.byKey(const Key('event.image')), findsNothing);
    });

    testWidgets('still reads when its picture will not load, and shows a placeholder in its place', (tester) async {
      await withNetworkImages(() async {
        await pump(
          tester,
          schoolEvent(
            image: const EventImage(id: 'f1', url: 'https://files.test/public/gone'),
          ),
        );
        // The picture is read outside the test's own clock.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Annual Day'), findsOneWidget);
        expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
        // It keeps the room the picture would have had, so the page does not jump.
        expect(tester.getSize(find.byKey(const Key('event.imagePlaceholder'))).height, 180);
      }, status: 404);
    });

    testWidgets('offers no Edit or Delete when the person may not change it', (tester) async {
      await pump(tester, schoolEvent());
      expect(find.byKey(const Key('event.edit')), findsNothing);
      expect(find.byKey(const Key('event.delete')), findsNothing);
    });

    testWidgets('offers Edit and Delete when it says the person may change it', (tester) async {
      await pump(tester, editable);
      expect(find.byKey(const Key('event.edit')), findsOneWidget);
      expect(find.byKey(const Key('event.delete')), findsOneWidget);
    });

    testWidgets('offers the view no way to change where the event belongs unless it is told the person is an Owner', (
      tester,
    ) async {
      await pump(tester, editable);
      expect(find.byKey(const Key('event.scope')), findsNothing);
    });

    testWidgets('Change where it belongs opens the sheet, and reads the event again once it moved', (tester) async {
      final institutions = MockInstitutionsRepository();
      when(institutions.institutions).thenAnswer((_) async => [summary()]);
      when(
        () => repository.changeScope(
          any(),
          scope: any(named: 'scope'),
          institutionId: any(named: 'institutionId'),
        ),
      ).thenAnswer((_) async => editable);
      getIt
        ..registerSingleton<EventsRepository>(repository)
        ..registerSingleton<InstitutionsRepository>(institutions);
      addTearDown(getIt.reset);
      await pump(tester, editable, owner: true);
      await tester.tap(find.byKey(const Key('event.scope')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('eventScope.save')), findsOneWidget);
      await tester.tap(find.byKey(const Key('eventScope.save')));
      await tester.pumpAndSettle();
      verify(() => repository.changeScope(editable, scope: EventScope.society)).called(1);
      expect(find.byKey(const Key('eventScope.save')), findsNothing);
      verify(() => repository.event('e1')).called(2);
    });

    testWidgets('Edit opens the form on this event, and reads the event again once it is saved', (tester) async {
      final t = await pump(tester, editable);
      await tester.tap(find.byKey(const Key('event.edit')));
      await tester.pumpAndSettle();
      expect(t.forms.single, isA<EventFormArgs>().having((args) => args.event, 'event', editable));
      verify(() => repository.event('e1')).called(1);
      await tester.tap(find.text('form saved'));
      await tester.pumpAndSettle();
      verify(() => repository.event('e1')).called(1);
    });

    testWidgets('Delete asks first, then removes the event and closes the screen with the list to read again', (
      tester,
    ) async {
      when(() => repository.remove('e1')).thenAnswer((_) async {});
      final t = await pump(tester, editable);
      await tester.tap(find.byKey(const Key('event.delete')));
      await tester.pumpAndSettle();
      expect(find.text('Delete this event?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      verify(() => repository.remove('e1')).called(1);
      expect(find.text('Event deleted'), findsOneWidget);
      expect(t.closed, [true]);
    });

    testWidgets('keeps the event when the person says Cancel', (tester) async {
      final t = await pump(tester, editable);
      await tester.tap(find.byKey(const Key('event.delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => repository.remove(any()));
      expect(t.closed, isEmpty);
    });

    testWidgets('says why a delete was refused and keeps the event', (tester) async {
      when(() => repository.remove('e1')).thenThrow(refusal('SCOPE_NOT_ALLOWED'));
      await pump(tester, editable);
      await tester.tap(find.byKey(const Key('event.delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('event.actionFailed')), findsOneWidget);
      expect(find.textContaining('Only an Owner can add or change an event of the whole Society'), findsOneWidget);
      expect(find.text('Annual Day'), findsOneWidget);
    });

    testWidgets('offers no way to change where the event belongs while the delete is on its way', (tester) async {
      final pending = Completer<void>();
      when(() => repository.remove('e1')).thenAnswer((_) => pending.future);
      await pump(tester, editable, owner: true);
      expect(tester.widget<AppButton>(find.byKey(const Key('event.scope'))).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('event.delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pump();
      expect(tester.widget<AppButton>(find.byKey(const Key('event.scope'))).onPressed, isNull);
      pending.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('shows the delete on its way, and offers neither action meanwhile', (tester) async {
      final pending = Completer<void>();
      when(() => repository.remove('e1')).thenAnswer((_) => pending.future);
      await pump(tester, editable);
      await tester.tap(find.byKey(const Key('event.delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pump();
      expect(tester.widget<AppButton>(find.byKey(const Key('event.edit'))).onPressed, isNull);
      expect(tester.widget<AppButton>(find.byKey(const Key('event.delete'))).onPressed, isNull);
      pending.complete();
      await tester.pumpAndSettle();
    });
  });

  group('the list', () {
    Future<List<Object?>> pump(WidgetTester tester, {required bool canAdd, List<SchoolEvent> events = const []}) async {
      when(
        () => repository.events(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => events);
      final forms = <Object?>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: BlocProvider(
                create: (_) => EventsBloc(repository, today: DateTime(2026, 11, 17))..add(const EventsRequested()),
                child: EventsView(canAdd: canAdd),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.eventForm,
            builder: (context, state) {
              forms.add(state.extra);
              return Scaffold(
                body: TextButton(onPressed: () => context.pop(true), child: const Text('form saved')),
              );
            },
          ),
          GoRoute(
            path: '/events/:id',
            builder: (context, state) => Scaffold(
              body: TextButton(onPressed: () => context.pop(), child: const Text('event closed')),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpAppScaled(
        Router(
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
        ),
        size: const Size(400, 900),
      );
      await tester.pumpAndSettle();
      return forms;
    }

    testWidgets('offers Add event to a person who may add events, which opens an empty form', (tester) async {
      final forms = await pump(tester, canAdd: true);
      await tester.tap(find.byKey(const Key('events.add')));
      await tester.pumpAndSettle();
      expect(forms.single, isA<EventFormArgs>().having((args) => args.event, 'event', isNull));
    });

    testWidgets('reads the list again once the event is added', (tester) async {
      await pump(tester, canAdd: true);
      verify(
        () => repository.events(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(1);
      await tester.tap(find.byKey(const Key('events.add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('form saved'));
      await tester.pumpAndSettle();
      verify(
        () => repository.events(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(1);
    });

    testWidgets('offers no Add event to a person who only reads', (tester) async {
      await pump(tester, canAdd: false);
      expect(find.byKey(const Key('events.add')), findsNothing);
    });

    testWidgets('reads the list again when an event closes, for the person who can change events', (tester) async {
      await pump(tester, canAdd: true, events: [schoolEvent()]);
      await tester.tap(find.byKey(const ValueKey('events.item.e1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('event closed'));
      await tester.pumpAndSettle();
      verify(
        () => repository.events(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(2);
    });

    testWidgets('does not read it again for a person who cannot change events', (tester) async {
      await pump(tester, canAdd: false, events: [schoolEvent()]);
      await tester.tap(find.byKey(const ValueKey('events.item.e1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('event closed'));
      await tester.pumpAndSettle();
      verify(
        () => repository.events(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(1);
    });
  });

  group('the page', () {
    for (final (role, moves) in [
      (RoleCode.societyOwner, true),
      (RoleCode.institutionAdmin, false),
    ]) {
      testWidgets('${moves ? 'offers' : 'does not offer'} Change where it belongs to ${role.name}', (tester) async {
        when(() => repository.event('e1')).thenAnswer((_) async => schoolEvent(canEdit: true));
        final session = _MockSessionBloc();
        final active = AuthContext(role: role, societyId: 's1', societyName: 'North Trust');
        when(() => session.state).thenReturn(
          SessionAuthenticated(AuthSession(person: testPerson, contexts: [active], activeContext: active)),
        );
        getIt.registerSingleton<EventsRepository>(repository);
        addTearDown(getIt.reset);
        final children = _MockActiveChildBloc();
        when(() => children.state).thenReturn(const ActiveChildNone());
        await tester.pumpAppScaled(
          MultiBlocProvider(
            providers: [
              BlocProvider<SessionBloc>.value(value: session),
              BlocProvider<ActiveChildBloc>.value(value: children),
            ],
            child: const EventPage(id: 'e1'),
          ),
          size: const Size(400, 1000),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('event.edit')), findsOneWidget);
        expect(find.byKey(const Key('event.scope')), moves ? findsOneWidget : findsNothing);
      });
    }

    for (final (role, adds) in [
      (RoleCode.societyOwner, true),
      (RoleCode.institutionAdmin, true),
      (RoleCode.teacherStaff, false),
    ]) {
      testWidgets('${adds ? 'offers' : 'does not offer'} Add event to ${role.name}', (tester) async {
        final session = _MockSessionBloc();
        final active = AuthContext(role: role, societyId: 's1', societyName: 'North Trust');
        when(() => session.state).thenReturn(
          SessionAuthenticated(AuthSession(person: testPerson, contexts: [active], activeContext: active)),
        );
        getIt.registerSingleton<EventsRepository>(repository);
        addTearDown(getIt.reset);
        final children = _MockActiveChildBloc();
        when(() => children.state).thenReturn(const ActiveChildNone());
        await tester.pumpAppScaled(
          MultiBlocProvider(
            providers: [
              BlocProvider<SessionBloc>.value(value: session),
              BlocProvider<ActiveChildBloc>.value(value: children),
            ],
            child: EventsPage(clock: () => DateTime(2026, 11, 17)),
          ),
          size: const Size(400, 900),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('events.add')), adds ? findsOneWidget : findsNothing);
      });
    }
  });
}
