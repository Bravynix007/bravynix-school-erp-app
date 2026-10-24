import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';
import 'package:equatable/equatable.dart';

/// Why the app signed out on its own: the `reason` values of API design 6.4,
/// and the refresh codes of 10.3.
enum SessionEndReason {
  expired,
  blocked,
  signedOutElsewhere,
  adminRevoked,
  emailChanged,
  other;

  static SessionEndReason from(ApiFailure failure) => switch (failure.details['reason']) {
    'expired' => expired,
    'blocked' => blocked,
    'logout' || 'logout_all' || 'token_reused' => signedOutElsewhere,
    'admin_revoked' => adminRevoked,
    'email_changed' => emailChanged,
    _ => switch (failure.code) {
      'TOKEN_EXPIRED' || 'REFRESH_TOKEN_INVALID' => expired,
      'REFRESH_TOKEN_REUSED' => signedOutElsewhere,
      'ACCOUNT_BLOCKED' => blocked,
      _ => other,
    },
  };
}

sealed class SessionEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// App start: restore the stored session, if any.
final class SessionStarted extends SessionEvent {
  const new();
}

final class SessionSignedIn extends SessionEvent {
  const new(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => [session];
}

final class SessionLogoutRequested extends SessionEvent {
  const new({this.everywhere = false});

  final bool everywhere;

  @override
  List<Object?> get props => [everywhere];
}

final class _SessionEnded extends SessionEvent {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

sealed class SessionState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Restoring on start; the splash is showing.
final class SessionUnknown extends SessionState {
  const new();
}

/// Could not check the stored session (offline, 503). The splash offers Retry.
final class SessionRestoreFailed extends SessionState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

final class SessionAuthenticated extends SessionState {
  const new(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => [session];
}

final class SessionUnauthenticated extends SessionState {
  const new({this.endReason});

  /// Set when the app was signed out by the server, so login can say why.
  final SessionEndReason? endReason;

  @override
  List<Object?> get props => [endReason];
}

/// The app-wide session. The router redirects on its state; screens read the
/// person and active context from it.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  new(this._auth) : super(const SessionUnknown()) {
    on<SessionStarted>(_onStarted);
    on<SessionSignedIn>((event, emit) => emit(SessionAuthenticated(event.session)));
    on<SessionLogoutRequested>(_onLogout);
    on<_SessionEnded>(_onEnded);
    _ended = _auth.sessionEnded.listen((failure) => add(_SessionEnded(failure)));
  }

  final AuthRepository _auth;
  late final StreamSubscription<ApiFailure> _ended;

  Future<void> _onStarted(SessionStarted event, Emitter<SessionState> emit) async {
    emit(const SessionUnknown());
    try {
      final session = await _auth.restoreSession();
      emit(session == null ? const SessionUnauthenticated() : SessionAuthenticated(session));
    } on ApiFailure catch (failure) {
      emit(SessionRestoreFailed(failure));
    }
  }

  Future<void> _onLogout(SessionLogoutRequested event, Emitter<SessionState> emit) async {
    await _auth.logout(everywhere: event.everywhere);
    emit(const SessionUnauthenticated());
  }

  void _onEnded(_SessionEnded event, Emitter<SessionState> emit) {
    // A late 401 after logging out must not show "signed out" again.
    if (state is SessionUnauthenticated) return;
    emit(SessionUnauthenticated(endReason: SessionEndReason.from(event.failure)));
  }

  @override
  Future<void> close() async {
    await _ended.cancel();
    await super.close();
  }
}
