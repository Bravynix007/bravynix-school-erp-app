import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository auth;
  late StreamController<ApiFailure> ended;

  setUp(() {
    auth = MockAuthRepository();
    ended = StreamController<ApiFailure>.broadcast();
    when(() => auth.sessionEnded).thenAnswer((_) => ended.stream);
  });

  tearDown(() => ended.close());

  blocTest<SessionBloc, SessionState>(
    'restores a stored session on start',
    build: () {
      when(() => auth.restoreSession()).thenAnswer((_) async => testSession);
      return SessionBloc(auth);
    },
    act: (bloc) => bloc.add(const SessionStarted()),
    expect: () => [const SessionUnknown(), const SessionAuthenticated(testSession)],
  );

  blocTest<SessionBloc, SessionState>(
    'with no stored session, is signed out',
    build: () {
      when(() => auth.restoreSession()).thenAnswer((_) async => null);
      return SessionBloc(auth);
    },
    act: (bloc) => bloc.add(const SessionStarted()),
    expect: () => [const SessionUnknown(), const SessionUnauthenticated()],
  );

  blocTest<SessionBloc, SessionState>(
    'offline at start keeps the tokens and offers retry',
    build: () {
      when(() => auth.restoreSession()).thenThrow(const ApiFailure.network());
      return SessionBloc(auth);
    },
    act: (bloc) => bloc.add(const SessionStarted()),
    expect: () => [const SessionUnknown(), const SessionRestoreFailed(ApiFailure.network())],
  );

  blocTest<SessionBloc, SessionState>(
    'a server-ended session signs out with the reason',
    build: () => SessionBloc(auth),
    seed: () => const SessionAuthenticated(testSession),
    act: (_) => ended.add(
      const ApiFailure(statusCode: 401, code: 'SESSION_ENDED', message: 'x', details: {'reason': 'blocked'}),
    ),
    expect: () => [const SessionUnauthenticated(endReason: SessionEndReason.blocked)],
  );

  blocTest<SessionBloc, SessionState>(
    'a late 401 after logging out changes nothing',
    build: () => SessionBloc(auth),
    seed: () => const SessionUnauthenticated(),
    act: (_) => ended.add(const ApiFailure(statusCode: 401, code: 'SESSION_ENDED', message: 'x')),
    expect: () => <SessionState>[],
  );

  blocTest<SessionBloc, SessionState>(
    'logout calls the API and signs out',
    build: () {
      when(() => auth.logout(everywhere: any(named: 'everywhere'))).thenAnswer((_) async {});
      return SessionBloc(auth);
    },
    seed: () => const SessionAuthenticated(testSession),
    act: (bloc) => bloc.add(const SessionLogoutRequested(everywhere: true)),
    expect: () => [const SessionUnauthenticated()],
    verify: (_) => verify(() => auth.logout(everywhere: true)).called(1),
  );

  test('end reasons map from the API', () {
    ApiFailure withReason(String reason) =>
        ApiFailure(statusCode: 401, code: 'SESSION_ENDED', message: '', details: {'reason': reason});
    expect(SessionEndReason.from(withReason('expired')), SessionEndReason.expired);
    expect(SessionEndReason.from(withReason('logout_all')), SessionEndReason.signedOutElsewhere);
    expect(SessionEndReason.from(withReason('something_new')), SessionEndReason.other);
  });
}
