import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';
import 'package:equatable/equatable.dart';

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
class LoginCubit extends Cubit<LoginState> {
  new(this._auth, {DateTime Function()? clock}) : _now = clock ?? DateTime.now, super(const LoginState());

  final AuthRepository _auth;

  /// Injectable so tests control the resend timer.
  final DateTime Function() _now;

  /// Errors after which the current code is dead.
  static const _deadCode = {'OTP_EXPIRED', 'OTP_ATTEMPTS_EXCEEDED'};

  Future<void> submitEmail(String email) async {
    if (state.isSubmitting) return;
    final normalised = email.trim().toLowerCase();
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

  Future<void> resend() async {
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

  Future<void> submitCode(String code) async {
    if (state.isSubmitting || code.length != 6) return;
    emit(state.copyWith(status: LoginStatus.submitting, failure: () => null));
    try {
      final session = await _auth.verifyOtp(email: state.email, code: code);
      emit(state.copyWith(status: LoginStatus.success, session: session));
    } on ApiFailure catch (failure) {
      // A locked email stays on this step: the screen offers only a fresh start.
      emit(state.copyWith(status: LoginStatus.idle, failure: () => failure));
    }
  }

  void changeEmail() => emit(LoginState(email: state.email));

  bool isCodeDead() => state.failure != null && _deadCode.contains(state.failure!.code);

  LoginState _codeStep(String email, Duration resendAfter) => LoginState(
    step: LoginStep.code,
    email: email,
    resendAvailableAt: _now().add(resendAfter),
  );
}
