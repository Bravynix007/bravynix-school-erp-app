import 'package:bravynix_school_erp/core/network/api_envelope.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

/// Marks a request that must go without the access token (the OTP calls).
const anonymousExtra = 'anonymous';

/// Exchanges a refresh token for a new pair (AUTH-05). Returns null when the
/// session cannot be continued.
abstract class TokenRefresher {
  Future<AuthTokens?> refresh(String refreshToken);
}

class DioTokenRefresher implements TokenRefresher {
  new(this._dio);

  /// A Dio without the auth interceptor, so a refresh never recurses.
  final Dio _dio;

  @override
  Future<AuthTokens?> refresh(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('auth/refresh', data: {'refreshToken': refreshToken});
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return null;
      final access = data['accessToken'] as String?;
      final refresh = data['refreshToken'] as String?;
      return access != null && refresh != null ? AuthTokens(accessToken: access, refreshToken: refresh) : null;
    } on DioException {
      return null;
    }
  }
}

/// Adds `Authorization: Bearer`, and on 401 `TOKEN_EXPIRED` refreshes once and
/// repeats the call (API design 8.2).
///
/// It is a [QueuedInterceptor], so errors are handled one at a time and
/// refreshes are serialised: a refresh token is single use and a second use
/// ends the session (API design 10.3). A request that failed with an older
/// token than the stored one is simply repeated with the new token.
class AuthInterceptor extends QueuedInterceptor {
  new({required this.storage, required this.refresher, required this.retryDio, required this.events});

  final TokenStorage storage;
  final TokenRefresher refresher;

  /// Repeats requests outside this interceptor's queue, which would otherwise deadlock.
  final Dio retryDio;
  final ApiEvents events;

  static const _usedTokenExtra = 'auth.usedToken';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[anonymousExtra] != true) {
      final tokens = await storage.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
        options.extra[_usedTokenExtra] = tokens.accessToken;
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final response = err.response;
    if (response?.statusCode != 401 || options.extra[anonymousExtra] == true) {
      return handler.next(err);
    }

    final failure = ApiEnvelope.failureFrom(401, response?.data);
    if (failure.code != 'TOKEN_EXPIRED') {
      await _endSession(failure);
      return handler.next(err);
    }

    final current = await storage.read();
    if (current == null) {
      await _endSession(_expired(failure));
      return handler.next(err);
    }

    var tokens = current;
    if (current.accessToken == options.extra[_usedTokenExtra]) {
      final refreshed = await refresher.refresh(current.refreshToken);
      if (refreshed == null) {
        await _endSession(_expired(failure));
        return handler.next(err);
      }
      await storage.write(refreshed);
      tokens = refreshed;
    }

    try {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      options.extra[_usedTokenExtra] = tokens.accessToken;
      handler.resolve(await retryDio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401) {
        await _endSession(ApiEnvelope.failureFrom(401, retryError.response?.data));
      }
      handler.next(retryError);
    }
  }

  ApiFailure _expired(ApiFailure from) => ApiFailure(
    statusCode: 401,
    code: 'SESSION_ENDED',
    message: from.message,
    requestId: from.requestId,
    details: const {'reason': 'expired'},
  );

  Future<void> _endSession(ApiFailure failure) async {
    await storage.clear();
    events.emitSessionEnded(failure);
  }
}
