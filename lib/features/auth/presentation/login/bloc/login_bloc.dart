import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';
import 'package:equatable/equatable.dart';

sealed class LoginEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

final class LoginEmailSubmitted extends LoginEvent {
  const new(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

final class LoginResendRequested extends LoginEvent {
  const new();
}

final class LoginCodeSubmitted extends LoginEvent {
  const new(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

/// "Use a different email", and "Start again" after a lock.
final class LoginEmailReset extends LoginEvent {
  const new();
}

enum LoginStep { email, code }

enum LoginStatus { idle, submitting, success }

class LoginState extends Equatable {
  const new({
    this.step = LoginStep.email,
    this.status = LoginStatus.idle,
    this.email = '',
    this.failure,
    this.resendAvailableAt,
    this.session,
  });

  final LoginStep step;
  final LoginStatus status;
  final String email;
  final ApiFailure? failure;

  /// When "Resend code" unlocks (60 s gap, API design 6.2).
  final DateTime? resendAvailableAt;

  /// Set on success; the page hands it to the session bloc.
  final AuthSession? session;

  bool get isSubmitting => status == LoginStatus.submitting;

  /// Errors after which the current code is dead.
  static const _deadCode = {'OTP_EXPIRED', 'OTP_ATTEMPTS_EXCEEDED'};

  bool get isCodeDead => failure != null && _deadCode.contains(failure!.code);

  LoginState copyWith({
    LoginStep? step,
    LoginStatus? status,
    String? email,
    ApiFailure? Function()? failure,
    DateTime? resendAvailableAt,
    AuthSession? session,
  }) => LoginState(
    step: step ?? this.step,
    status: status ?? this.status,
    email: email ?? this.email,
    failure: failure != null ? failure() : this.failure,
    resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
    session: session ?? this.session,
  );

  @override
  List<Object?> get props => [step, status, email, failure, resendAvailableAt, session];
}

/// Email → 6-digit code (API design 6.2). No passwords anywhere (PRD 5).
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  new(this._auth, {DateTime Function()? clock}) : _now = clock ?? DateTime.now, super(const LoginState()) {
    on<LoginEmailSubmitted>(_onEmailSubmitted);
    on<LoginResendRequested>(_onResend);
    on<LoginCodeSubmitted>(_onCodeSubmitted);
    on<LoginEmailReset>((event, emit) => emit(LoginState(email: state.email)));
  }

  final AuthRepository _auth;

  /// Injectable so tests control the resend timer.
  final DateTime Function() _now;

  Future<void> _onEmailSubmitted(LoginEmailSubmitted event, Emitter<LoginState> emit) async {
    if (state.isSubmitting) return;
    final normalised = event.email.trim().toLowerCase();
    emit(state.copyWith(email: normalised, status: LoginStatus.submitting, failure: () => null));
    try {
      final sent = await _auth.requestOtp(normalised);
      emit(_codeStep(normalised, sent.resendAfter));
    } on ApiFailure catch (failure) {
      // A code went out less than a minute ago: it is still valid, so go on.
      if (failure.code == 'OTP_RESEND_TOO_SOON') {
        emit(_codeStep(normalised, failure.retryAfter ?? const Duration(seconds: 60)));
        return;
      }
      emit(state.copyWith(status: LoginStatus.idle, failure: () => failure));
    }
  }

  Future<void> _onResend(LoginResendRequested event, Emitter<LoginState> emit) async {
    if (state.isSubmitting || state.step != LoginStep.code) return;
    emit(state.copyWith(status: LoginStatus.submitting, failure: () => null));
    try {
      final sent = await _auth.requestOtp(state.email);
      emit(_codeStep(state.email, sent.resendAfter));
    } on ApiFailure catch (failure) {
      emit(
        state.copyWith(
          status: LoginStatus.idle,
          failure: () => failure,
          resendAvailableAt: failure.retryAfter == null ? null : _now().add(failure.retryAfter!),
        ),
      );
    }
  }

  Future<void> _onCodeSubmitted(LoginCodeSubmitted event, Emitter<LoginState> emit) async {
    if (state.isSubmitting || event.code.length != 6) return;
    emit(state.copyWith(status: LoginStatus.submitting, failure: () => null));
    try {
      final session = await _auth.verifyOtp(email: state.email, code: event.code);
      emit(state.copyWith(status: LoginStatus.success, session: session));
    } on ApiFailure catch (failure) {
      // A locked email stays on this step: the screen offers only a fresh start.
      emit(state.copyWith(status: LoginStatus.idle, failure: () => failure));
    }
  }

  LoginState _codeStep(String email, Duration resendAfter) => LoginState(
    step: LoginStep.code,
    email: email,
    resendAvailableAt: _now().add(resendAfter),
  );
}
