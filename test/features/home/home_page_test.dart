import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/home/presentation/home_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

void main() {
  Future<void> pumpHome(WidgetTester tester, Person person) {
    final session = _MockSessionBloc();
    when(() => session.state).thenReturn(SessionAuthenticated(AuthSession(person: person, contexts: const [])));
    return tester.pumpApp(BlocProvider<SessionBloc>.value(value: session, child: const HomePage()));
  }

  testWidgets('greets the person by first name', (tester) async {
    await pumpHome(tester, testPerson);
    expect(find.text('Welcome, Asha'), findsOneWidget);
  });

  testWidgets('greets a person with no name yet by their email', (tester) async {
    await pumpHome(tester, const Person(id: 'p2', email: 'new.owner@two-worlds.test', preferredLanguage: 'en'));
    expect(find.text('Welcome, new.owner@two-worlds.test'), findsOneWidget);
  });
}
