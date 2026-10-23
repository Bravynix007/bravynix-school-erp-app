import 'package:bravynix_school_erp/core/network/api_failure.dart';

/// Pagination from `meta` (API design 7.4, 7.5): either page mode or cursor mode.
sealed class PageInfo {
  const new();

  static PageInfo? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    if (json.containsKey('nextCursor') || json.containsKey('hasMore')) {
      return CursorPage(
        limit: (json['limit'] as num?)?.toInt() ?? 0,
        nextCursor: json['nextCursor'] as String?,
        hasMore: json['hasMore'] as bool? ?? false,
      );
    }
    if (json.containsKey('totalItems')) {
      return NumberedPage(
        page: (json['page'] as num?)?.toInt() ?? 1,
        limit: (json['limit'] as num?)?.toInt() ?? 0,
        totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      );
    }
    return null;
  }
}

class NumberedPage extends PageInfo {
  const new({required this.page, required this.limit, required this.totalItems, required this.totalPages});

  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
}

class CursorPage extends PageInfo {
  const new({required this.limit, required this.nextCursor, required this.hasMore});

  final int limit;
  final String? nextCursor;
  final bool hasMore;
}

/// The envelope every answer carries (API design 7.1):
/// `{ success, statusCode, code, message, data, meta, errors?, requestId }`.
class ApiEnvelope<T> {
  const new({
    required this.statusCode,
    required this.code,
    required this.message,
    required this.data,
    required this.requestId,
    this.meta,
  });

  final int statusCode;
  final String code;
  final String message;
  final T data;
  final PageInfo? meta;
  final String requestId;

  static const _envelopeKeys = {'success', 'statusCode', 'code', 'message', 'data', 'meta', 'errors', 'requestId'};

  static bool isEnvelope(Object? body) =>
      body is Map<String, dynamic> &&
      body.containsKey('success') &&
      body.containsKey('code') &&
      body.containsKey('statusCode');

  /// Parses a success answer; [parse] turns `data` into the caller's type.
  static ApiEnvelope<T> parse<T>(Map<String, dynamic> body, T Function(Object? data) parse) => ApiEnvelope(
    statusCode: (body['statusCode'] as num).toInt(),
    code: body['code'] as String,
    message: body['message'] as String? ?? '',
    data: parse(body['data']),
    meta: PageInfo.fromJson(body['meta']),
    requestId: body['requestId'] as String? ?? '',
  );

  /// Turns an error envelope into an [ApiFailure]; anything else is unexpected.
  static ApiFailure failureFrom(int status, Object? body, {Duration? retryAfter, String? requestIdHeader}) {
    if (!isEnvelope(body)) return ApiFailure.unexpected(status, requestId: requestIdHeader);
    final map = body! as Map<String, dynamic>;
    final data = map['data'];
    return ApiFailure(
      statusCode: status,
      code: map['code'] as String,
      message: map['message'] as String? ?? '',
      requestId: map['requestId'] as String? ?? requestIdHeader,
      fieldErrors: [
        for (final error in (map['errors'] as List<dynamic>? ?? const []))
          if (error is Map<String, dynamic>) FieldError.fromJson(error),
      ],
      details: {
        if (data is Map<String, dynamic>) ...data,
        for (final entry in map.entries)
          if (!_envelopeKeys.contains(entry.key)) entry.key: entry.value,
      },
      retryAfter: retryAfter,
    );
  }
}
