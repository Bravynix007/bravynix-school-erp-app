import 'package:bravynix_school_erp/core/network/api_envelope.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

/// Marks a request that must go without the access token (the OTP calls).
const anonymousExtra = 'anonymous';

/// What a refresh came to. Only a 401 from the API ends the session; any
/// other failure (offline, timeout, 5xx, 426) is thrown as a [DioException]
/// and leaves the tokens alone (API design 8.2).
sealed class RefreshResult {
  const new();
}

class Refreshed extends RefreshResult {
  const new(this.tokens);

  final AuthTokens tokens;
}

/// The API refused the refresh token: the session is over, for [failure]'s reason.
class RefreshRefused extends RefreshResult {
  const new(this.failure);

  final ApiFailure failure;
}

/// Exchanges a refresh token for a new pair (AUTH-05).
abstract class TokenRefresher {
  /// Throws a [DioException] when the API could not answer.
  Future<RefreshResult> refresh(String refreshToken);
}

class DioTokenRefresher implements TokenRefresher {
  new(this._dio);

  /// A Dio without the auth interceptor, so a refresh never recurses.
  final Dio _dio;

  @override
  Future<RefreshResult> refresh(String refreshToken) async {
    final Response<Object?> response;
    try {
      response = await _dio.post<Object?>('auth/refresh', data: {'refreshToken': refreshToken});
    } on DioException catch (error) {
      final answer = error.response;
      if (answer?.statusCode == 401) return RefreshRefused(ApiEnvelope.failureFrom(401, answer?.data));
      rethrow;
    }
    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : null;
    final access = data is Map<String, dynamic> ? data['accessToken'] : null;
    final refresh = data is Map<String, dynamic> ? data['refreshToken'] : null;
    if (access is String && refresh is String) {
      return Refreshed(AuthTokens(accessToken: access, refreshToken: refresh));
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: ApiFailure.unexpected(response.statusCode ?? 0),
    );
  }
}

/// Adds `Authorization: Bearer`, and on 401 `TOKEN_EXPIRED` refreshes once and
/// repeats the call (API design 8.2).
///
/// It is a [QueuedInterceptor], so errors are handled one at a time and
/// refreshes are serialised: a refresh token is single use and a second use
/// ends the session (API design 10.3). A request that failed with an older
/// token than the stored one is simply repeated with the new token. Every
/// path calls the handler exactly once, even when storage throws, because a
/// handler left uncalled stalls the whole queue.
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
    try {
      if (options.extra[anonymousExtra] != true) {
        final tokens = await storage.read();
        if (tokens != null) {
          options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          options.extra[_usedTokenExtra] = tokens.accessToken;
        }
      }
      handler.next(options);
    } on Object catch (error, stackTrace) {
      handler.reject(DioException(requestOptions: options, error: error, stackTrace: stackTrace));
    }
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      final response = await _recover(err);
      if (response != null) return handler.resolve(response);
      handler.next(err);
    } on DioException catch (error) {
      handler.next(error);
    } on Object catch (error, stackTrace) {
      handler.next(DioException(requestOptions: err.requestOptions, error: error, stackTrace: stackTrace));
    }
  }

  /// The repeated call's response, or null to pass [err] on. Throws the
  /// [DioException] to pass on instead.
  Future<Response<dynamic>?> _recover(DioException err) async {
    final options = err.requestOptions;
    final response = err.response;
    if (response?.statusCode != 401 || options.extra[anonymousExtra] == true) return null;

    final failure = ApiEnvelope.failureFrom(401, response?.data);
    if (failure.code != 'TOKEN_EXPIRED') {
      await _endSession(failure);
      return null;
    }

    final current = await storage.read();
    if (current == null) {
      await _endSession(_expired(failure));
      return null;
    }

    var tokens = current;
    if (current.accessToken == options.extra[_usedTokenExtra]) {
      // A network failure here is thrown on as it is: the tokens stay.
      switch (await refresher.refresh(current.refreshToken)) {
        case RefreshRefused(failure: final refused):
          // Keep the server's reason: REFRESH_TOKEN_REUSED, blocked, logout_all.
          await _endSession(refused);
          throw DioException(
            requestOptions: options,
            response: response,
            type: DioExceptionType.badResponse,
            error: refused,
          );
        case Refreshed(tokens: final fresh):
          await storage.write(fresh);
          tokens = fresh;
      }
    }

    options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    options.extra[_usedTokenExtra] = tokens.accessToken;
    try {
      return await retryDio.fetch<dynamic>(options);
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401) {
        await _endSession(ApiEnvelope.failureFrom(401, retryError.response?.data));
      }
      rethrow;
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
    try {
      await storage.clear();
    } finally {
      events.emitSessionEnded(failure);
    }
  }
}
