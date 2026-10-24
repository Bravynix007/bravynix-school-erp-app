import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/cubit/login_cubit.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/login_page.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/pump_app.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

void main() {
  late MockAuthRepository auth;
  late _MockSessionBloc session;

  setUpAll(() => registerFallbackValue(const SessionStarted()));

  setUp(() {
    auth = MockAuthRepository();
    session = _MockSessionBloc();
    when(() => session.state).thenReturn(const SessionUnauthenticated());
  });

  Future<void> pumpLogin(WidgetTester tester) => tester.pumpApp(
    BlocProvider<SessionBloc>.value(
      value: session,
      child: BlocProvider(create: (_) => LoginCubit(auth), child: const LoginView()),
    ),
  );

  testWidgets('checks the email before calling the API', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(find.byKey(const Key('login.email')), 'asha@');
    await tester.tap(find.byKey(const Key('login.sendCode')));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    verifyNever(() => auth.requestOtp(any()));
  });

  testWidgets('email → code → signed in', (tester) async {
    when(() => auth.requestOtp(any())).thenAnswer(
      (_) async => const OtpRequested(resendAfter: Duration(seconds: 60), expiresIn: Duration(minutes: 10)),
    );
    when(
      () => auth.verifyOtp(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => testSession);

    await pumpLogin(tester);
    await tester.enterText(find.byKey(const Key('login.email')), 'asha.rao@example.com');
    await tester.tap(find.byKey(const Key('login.sendCode')));
    await tester.pumpAndSettle();

    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('Resend code in'), findsOneWidget);

    // Typing the sixth digit submits.
    await tester.enterText(find.byKey(const Key('login.code')), '482017');
    await tester.pump();

    verify(() => auth.verifyOtp(email: 'asha.rao@example.com', code: '482017')).called(1);
    verify(() => session.add(const SessionSignedIn(testSession))).called(1);
  });

  testWidgets('a wrong code shows the attempts left', (tester) async {
    when(() => auth.requestOtp(any())).thenAnswer(
      (_) async => const OtpRequested(resendAfter: Duration(seconds: 60), expiresIn: Duration(minutes: 10)),
    );
    when(
      () => auth.verifyOtp(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    ).thenThrow(
      const ApiFailure(statusCode: 401, code: 'OTP_INVALID', message: '', details: {'attemptsLeft': 3}),
    );

    await pumpLogin(tester);
    await tester.enterText(find.byKey(const Key('login.email')), 'asha.rao@example.com');
    await tester.tap(find.byKey(const Key('login.sendCode')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('login.code')), '111111');
    await tester.pump();

    expect(find.text('Incorrect code. 3 attempts left.'), findsOneWidget);
  });

  testWidgets('says why the app signed out', (tester) async {
    when(() => session.state).thenReturn(const SessionUnauthenticated(endReason: SessionEndReason.signedOutElsewhere));
    await pumpLogin(tester);
    expect(find.text('You were signed out from another device.'), findsOneWidget);
  });

  testWidgets('says when logging out could not finish on this phone', (tester) async {
    when(() => session.state).thenReturn(const SessionUnauthenticated(endReason: SessionEndReason.signOutIncomplete));
    await pumpLogin(tester);
    expect(
      find.text("You're signed out, but this phone couldn't forget your sign-in. Sign in and log out again to finish."),
      findsOneWidget,
    );
  });

  testWidgets('is usable with a large text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpLogin(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('login.sendCode')), findsOneWidget);
  });
}
