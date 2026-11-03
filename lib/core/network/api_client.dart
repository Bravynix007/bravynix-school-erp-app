import 'dart:developer' show log;
import 'dart:io' show HttpHeaders, SocketException;

import 'package:bravynix_school_erp/core/network/api_envelope.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/interceptors/auth_interceptor.dart';
import 'package:bravynix_school_erp/core/network/interceptors/headers_interceptor.dart';
import 'package:dio/dio.dart';

enum HttpMethod { get, post, put, patch, delete }

/// What [ApiClient.conditional] got: nothing new (304), or the data with the tag that names it.
class ConditionalData<T> {
  const new changed(T this.data, {this.etag}) : isModified = true;

  const new notModified() : data = null, etag = null, isModified = false;

  final bool isModified;
  final T? data;
  final String? etag;
}

/// The one way features call the API. It unwraps the envelope and turns every
/// failure into an [ApiFailure] (API design 7, 8). Repositories call it; blocs
/// and widgets never see Dio.
class ApiClient {
  new(this._dio, {required this._events});

  final Dio _dio;
  final ApiEvents _events;

  /// Timeouts per API design 8.2: 15 seconds (the AI chat passes its own 25).
  static const defaultTimeout = Duration(seconds: 15);

  Future<ApiEnvelope<T>> request<T>(
    String path, {
    required T Function(Object? data) parse,
    HttpMethod method = HttpMethod.get,
    Object? body,
    Map<String, Object?>? query,
    bool anonymous = false,
    String? idempotencyKey,
    Duration? timeout,
    CancelToken? cancelToken,
  }) async {
    Response<Object?>? response;
    try {
      response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: _query(query),
        cancelToken: cancelToken,
        options: Options(
          method: method.name.toUpperCase(),
          extra: {anonymousExtra: anonymous},
          headers: {'Idempotency-Key': ?idempotencyKey},
          receiveTimeout: timeout,
        ),
      );
      return _unwrap(response, parse);
    } on Object catch (error, stackTrace) {
      throw _asFailure(path, error, stackTrace, response);
    }
  }

  /// A read the server may answer 304 to when [etag] still matches (API design 19.2): the caller keeps what it
  /// holds. A 200 carries the new data and the tag to send next time.
  Future<ConditionalData<T>> conditional<T>(
    String path, {
    required T Function(Object? data) parse,
    String? etag,
    Map<String, Object?>? query,
  }) async {
    Response<Object?>? response;
    try {
      response = await _dio.get<Object?>(
        path,
        queryParameters: _query(query),
        options: Options(
          headers: {HttpHeaders.ifNoneMatchHeader: ?etag},
          validateStatus: (status) => status != null && ((status >= 200 && status < 300) || status == 304),
        ),
      );
      if (response.statusCode == 304) return const ConditionalData.notModified();
      return ConditionalData.changed(
        _unwrap(response, parse).data,
        etag: response.headers.value(HttpHeaders.etagHeader),
      );
    } on Object catch (error, stackTrace) {
      throw _asFailure(path, error, stackTrace, response);
    }
  }

  ApiEnvelope<T> _unwrap<T>(Response<Object?> response, T Function(Object? data) parse) {
    final data = response.data;
    if (!ApiEnvelope.isEnvelope(data)) {
      throw ApiFailure.unexpected(response.statusCode ?? 0, requestId: _requestId(response));
    }
    return ApiEnvelope.parse(data! as Map<String, dynamic>, parse);
  }

  ApiFailure _asFailure(String path, Object error, StackTrace stackTrace, Response<Object?>? response) {
    if (error is ApiFailure) return error;
    if (error is DioException) {
      final failure = _toFailure(error);
      if (failure.isUpdateRequired) _events.emitUpdateRequired(failure);
      return failure;
    }
    // An answer that does not match its model (a cast or format error) is
    // still an ApiFailure, so callers and the splash never hang on it. It
    // is logged, so a parsing bug of ours is not hidden (re-review R-A9).
    log('Unreadable answer for $path', name: 'api', error: error, stackTrace: stackTrace);
    return ApiFailure.unexpected(response?.statusCode ?? 0, requestId: _requestId(response));
  }

  /// `data` only, for the common case.
  Future<T> data<T>(
    String path, {
    required T Function(Object? data) parse,
    HttpMethod method = HttpMethod.get,
    Object? body,
    Map<String, Object?>? query,
    bool anonymous = false,
    String? idempotencyKey,
  }) async => (await request(
    path,
    parse: parse,
    method: method,
    body: body,
    query: query,
    anonymous: anonymous,
    idempotencyKey: idempotencyKey,
  )).data;

  /// Repeated values mean OR: `status=1&status=2` (API design 13.1). Nulls are dropped.
  static Map<String, Object>? _query(Map<String, Object?>? query) {
    if (query == null) return null;
    return {
      for (final entry in query.entries)
        if (entry.value != null)
          entry.key: entry.value is Iterable ? (entry.value! as Iterable).toList() : entry.value!,
    };
  }

  static String? _requestId(Response<Object?>? response) => response?.headers.value(HeadersInterceptor.requestIdHeader);

  static ApiFailure _toFailure(DioException error) {
    final inner = error.error;
    if (inner is ApiFailure) return inner;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiFailure.timeout();
      case DioExceptionType.badResponse:
        final response = error.response;
        final retryAfter = int.tryParse(response?.headers.value(HttpHeaders.retryAfterHeader) ?? '');
        return ApiEnvelope.failureFrom(
          response?.statusCode ?? 0,
          response?.data,
          retryAfter: retryAfter != null && retryAfter > 0 ? Duration(seconds: retryAfter) : null,
          requestIdHeader: _requestId(response),
        );
      case DioExceptionType.cancel:
        return const ApiFailure(statusCode: 0, code: 'CANCELLED', message: 'Cancelled');
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const ApiFailure.network();
      case DioExceptionType.unknown:
        return inner is SocketException
            ? const ApiFailure.network()
            : const ApiFailure(statusCode: 0, code: 'CLIENT_ERROR', message: 'Something went wrong');
    }
  }
}
