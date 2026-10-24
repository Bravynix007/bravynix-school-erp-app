import 'dart:io' show HttpHeaders, SocketException;

import 'package:bravynix_school_erp/core/network/api_envelope.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/interceptors/auth_interceptor.dart';
import 'package:bravynix_school_erp/core/network/interceptors/headers_interceptor.dart';
import 'package:dio/dio.dart';

enum HttpMethod { get, post, put, patch, delete }

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
      final data = response.data;
      if (!ApiEnvelope.isEnvelope(data)) {
        throw ApiFailure.unexpected(response.statusCode ?? 0, requestId: _requestId(response));
      }
      return ApiEnvelope.parse(data! as Map<String, dynamic>, parse);
    } on DioException catch (error) {
      final failure = _toFailure(error);
      if (failure.isUpdateRequired) _events.emitUpdateRequired(failure);
      throw failure;
    } on ApiFailure {
      rethrow;
    } on Object {
      // An answer that does not match its model (a cast or format error) is
      // still an ApiFailure, so callers and the splash never hang on it.
      throw ApiFailure.unexpected(response?.statusCode ?? 0, requestId: _requestId(response));
    }
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
