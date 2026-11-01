import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/bloc/login_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  final now = DateTime.utc(2026, 10, 23, 4, 30);
  late MockAuthRepository auth;

  setUp(() => auth = MockAuthRepository());

  LoginBloc build() => LoginBloc(auth, clock: () => now);

  const sent = OtpRequested(resendAfter: Duration(seconds: 60), expiresIn: Duration(minutes: 10));
  final codeStep = LoginState(
    step: LoginStep.code,
    email: 'asha.rao@example.com',
    resendAvailableAt: now.add(const Duration(seconds: 60)),
  );

  blocTest<LoginBloc, LoginState>(
    'a sent code moves to the code step with the resend timer',
    build: build,
    setUp: () => when(() => auth.requestOtp(any())).thenAnswer((_) async => sent),
    act: (bloc) => bloc.add(const LoginEmailSubmitted('  Asha.Rao@Example.com ')),
    expect: () => [
      const LoginState(email: 'asha.rao@example.com', status: LoginStatus.submitting),
      codeStep,
    ],
    verify: (_) => verify(() => auth.requestOtp('asha.rao@example.com')).called(1),
  );

  blocTest<LoginBloc, LoginState>(
    'a code sent under a minute ago still moves on, waiting out Retry-After',
    build: build,
    setUp: () => when(() => auth.requestOtp(any())).thenThrow(
      const ApiFailure(
        statusCode: 429,
        code: 'OTP_RESEND_TOO_SOON',
        message: '',
        retryAfter: Duration(seconds: 42),
      ),
    ),
    act: (bloc) => bloc.add(const LoginEmailSubmitted('asha.rao@example.com')),
    skip: 1,
    expect: () => [
      LoginState(
        step: LoginStep.code,
        email: 'asha.rao@example.com',
        resendAvailableAt: now.add(const Duration(seconds: 42)),
      ),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'a wrong code stays on the code step with the failure',
    build: build,
    seed: () => codeStep,
    setUp: () =>
        when(
          () => auth.verifyOtp(
            email: any(named: 'email'),
            code: any(named: 'code'),
          ),
        ).thenThrow(
          const ApiFailure(statusCode: 401, code: 'OTP_INVALID', message: '', details: {'attemptsLeft': 4}),
        ),
    act: (bloc) => bloc.add(const LoginCodeSubmitted('111111')),
    skip: 1,
    expect: () => [
      isA<LoginState>()
          .having((s) => s.step, 'step', LoginStep.code)
          .having((s) => s.failure?.details['attemptsLeft'], 'attemptsLeft', 4),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'a locked email stays on the code step with the failure, for the screen to offer a fresh start',
    build: build,
    seed: () => codeStep,
    setUp: () =>
        when(
          () => auth.verifyOtp(
            email: any(named: 'email'),
            code: any(named: 'code'),
          ),
        ).thenThrow(
          const ApiFailure(statusCode: 423, code: 'AUTH_LOCKED', message: ''),
        ),
    act: (bloc) => bloc.add(const LoginCodeSubmitted('111111')),
    skip: 1,
    expect: () => [
      isA<LoginState>()
          .having((s) => s.step, 'step', LoginStep.code)
          .having((s) => s.failure?.isLockedOut, 'locked', isTrue),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'Resend answered with a lock stays on the code step, for the screen to offer a fresh start',
    build: build,
    seed: () => codeStep,
    setUp: () => when(() => auth.requestOtp(any())).thenThrow(
      const ApiFailure(statusCode: 423, code: 'AUTH_LOCKED', message: '', retryAfter: Duration(minutes: 30)),
    ),
    act: (bloc) => bloc.add(const LoginResendRequested()),
    skip: 1,
    expect: () => [
      isA<LoginState>()
          .having((s) => s.step, 'step', LoginStep.code)
          .having((s) => s.failure?.isLockedOut, 'locked', isTrue),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'Start again after a lock clears the failure and returns to the email step',
    build: build,
    seed: () => codeStep.copyWith(
      failure: () => const ApiFailure(statusCode: 423, code: 'AUTH_LOCKED', message: ''),
    ),
    act: (bloc) => bloc.add(const LoginEmailReset()),
    expect: () => [
      isA<LoginState>().having((s) => s.step, 'step', LoginStep.email).having((s) => s.failure, 'failure', isNull),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'a right code succeeds with the session',
    build: build,
    seed: () => codeStep,
    setUp: () => when(
      () => auth.verifyOtp(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => testSession),
    act: (bloc) => bloc.add(const LoginCodeSubmitted('482017')),
    skip: 1,
    expect: () => [
      isA<LoginState>()
          .having((s) => s.status, 'status', LoginStatus.success)
          .having((s) => s.session, 'session', testSession),
    ],
    verify: (_) => verify(() => auth.verifyOtp(email: 'asha.rao@example.com', code: '482017')).called(1),
  );

  blocTest<LoginBloc, LoginState>(
    'an incomplete code is not sent',
    build: build,
    seed: () => codeStep,
    act: (bloc) => bloc.add(const LoginCodeSubmitted('4820')),
    expect: () => <LoginState>[],
  );

  blocTest<LoginBloc, LoginState>(
    '"Use a different email" keeps the email for editing',
    build: build,
    seed: () => codeStep,
    act: (bloc) => bloc.add(const LoginEmailReset()),
    expect: () => [const LoginState(email: 'asha.rao@example.com')],
  );
}
