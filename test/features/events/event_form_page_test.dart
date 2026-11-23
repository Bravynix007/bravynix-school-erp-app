import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/classes/domain/class_catalogue.dart';
import 'package:bravynix_school_erp/features/events/domain/events_repository.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_form_page.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

void main() {
  setUp(() {
    final institutions = MockInstitutionsRepository();
    final catalogue = MockClassCatalogue();
    when(institutions.institutions).thenAnswer((_) async => [summary()]);
    when(catalogue.all).thenAnswer((_) async => const []);
    getIt
      ..registerSingleton<EventsRepository>(MockEventsRepository())
      ..registerSingleton<InstitutionsRepository>(institutions)
      ..registerSingleton<ClassCatalogue>(catalogue);
  });
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester, AuthContext context) async {
    final session = _MockSessionBloc();
    when(() => session.state).thenReturn(
      SessionAuthenticated(AuthSession(person: testPerson, contexts: [context], activeContext: context)),
    );
    await tester.pumpAppScaled(
      BlocProvider<SessionBloc>.value(
        value: session,
        child: EventFormPage(args: const EventFormArgs(), clock: () => DateTime(2026, 11, 17)),
      ),
      size: const Size(400, 3000),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers an Owner the whole Society as the place of a new event', (tester) async {
    await pump(tester, const AuthContext(role: RoleCode.societyOwner, societyId: 's1'));
    expect(find.byKey(const Key('eventForm.scope')), findsOneWidget);
  });

  testWidgets('offers an Admin no scope: an event is for an Institution of theirs', (tester) async {
    await pump(tester, const AuthContext(role: RoleCode.institutionAdmin, societyId: 's1'));
    expect(find.byKey(const Key('eventForm.scope')), findsNothing);
    expect(find.byKey(const Key('eventForm.institution')), findsOneWidget);
  });
}
