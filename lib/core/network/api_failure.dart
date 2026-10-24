import 'package:equatable/equatable.dart';

/// One field-level validation error from the envelope's `errors` (API design 8.1).
class FieldError extends Equatable {
  const new({required this.field, required this.code, required this.message});

  factory fromJson(Map<String, dynamic> json) => FieldError(
    field: json['field'] as String? ?? '',
    code: json['code'] as String? ?? '',
    message: json['message'] as String? ?? '',
  );

  final String field;
  final String code;
  final String message;

  @override
  List<Object?> get props => [field, code, message];
}

/// Every failed API call becomes an [ApiFailure] carrying the envelope's
/// stable `code`. UI code branches on [code], never on [message]
/// (API design 7.1, 8.2).
class ApiFailure extends Equatable implements Exception {
  const new({
    required this.statusCode,
    required this.code,
    required this.message,
    this.requestId,
    this.fieldErrors = const [],
    this.details = const {},
    this.retryAfter,
  });

  /// No answer at all: offline, DNS, TLS, or the 15-second timeout.
  const new network({String message = "Can't reach the server. Check your connection and try again."})
    : this(statusCode: 0, code: networkError, message: message);

  const new timeout()
    : this(statusCode: 0, code: timeoutError, message: 'The server took too long to answer. Try again.');

  /// An answer that is not the envelope (a proxy page, a 502 from the load balancer).
  const new unexpected(int statusCode, {String? requestId})
    : this(
        statusCode: statusCode,
        code: statusCode >= 500 ? 'INTERNAL_ERROR' : 'UNEXPECTED_RESPONSE',
        message: 'Something went wrong',
        requestId: requestId,
      );

  static const networkError = 'NETWORK_ERROR';
  static const timeoutError = 'TIMEOUT';

  final int statusCode;
  final String code;
  final String message;
  final String? requestId;
  final List<FieldError> fieldErrors;

  /// The error's `data`, such as `attemptsLeft`, `reason` or `storeUrl` (API design 8).
  final Map<String, dynamic> details;
  final Duration? retryAfter;

  bool get isNetwork => statusCode == 0;

  /// 401 other than TOKEN_EXPIRED: sign out locally (API design 8.2).
  bool get isSessionEnded => statusCode == 401 && code != 'TOKEN_EXPIRED';

  /// 429 and 503 (502 and 504 count as 503) may be retried after [retryAfter].
  bool get isRetryable => statusCode == 429 || statusCode == 503 || statusCode == 502 || statusCode == 504;

  /// 426: the app is below the minimum supported version (API design 5.2).
  bool get isUpdateRequired => statusCode == 426 || code == 'APP_UPDATE_REQUIRED';

  FieldError? fieldError(String field) {
    for (final error in fieldErrors) {
      if (error.field == field) return error;
    }
    return null;
  }

  @override
  List<Object?> get props => [statusCode, code, message, requestId, fieldErrors, details, retryAfter];

  @override
  String toString() => 'ApiFailure($statusCode $code: $message, requestId: $requestId)';
}
