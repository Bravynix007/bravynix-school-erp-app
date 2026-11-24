import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/files/data/file_models.dart';
import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:dio/dio.dart';

/// Sends the file to the store the ticket names (API design 15.1 step 2): a multipart form with every field of the
/// ticket and then the file (`POST`, the local store), or the bytes alone with the headers the ticket names (`PUT`,
/// R2). Either way there is no Authorization header, because the ticket is the permission. This is the one place
/// the app talks to the store, so it has its own Dio, with no base address and none of the API's interceptors.
class ObjectUploader {
  const new(this._dio);

  final Dio _dio;

  /// A file of 5 MB on a slow connection needs longer than an API call (15 seconds).
  static const sendTimeout = Duration(seconds: 60);

  /// A plain Dio for the store; tests pass an adapter through [adapter].
  static Dio createDio({HttpClientAdapter? adapter}) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: sendTimeout,
        receiveTimeout: sendTimeout,
      ),
    );
    if (adapter != null) dio.httpClientAdapter = adapter;
    return dio;
  }

  /// Sends [file]; [onProgress] gets the share sent, from 0 to 1. Throws [ApiFailure]: the network ones as for the API,
  /// and `UPLOAD_REFUSED` (or the store's own code, such as `BAD_UPLOAD` or `ALREADY_UPLOADED`) for a refusal.
  Future<void> send(
    UploadTicket ticket,
    ChosenFile file, {
    void Function(double sent)? onProgress,
    CancelToken? cancelToken,
  }) async {
    void progress(int sent, int total) {
      if (onProgress != null && total > 0) onProgress(sent / total);
    }

    try {
      if (ticket.method == 'PUT') {
        // The ticket was signed for this type and size, so the headers are the ones it names. The length is left out
        // because Dio sets it from the bytes, which are exactly the size the ticket was signed for; sending it twice
        // would only risk two values.
        await _dio.put<Object?>(
          ticket.url,
          data: file.bytes,
          options: Options(
            headers: {
              for (final header in ticket.headers.entries)
                if (header.key.toLowerCase() != 'content-length') header.key: header.value,
            },
          ),
          cancelToken: cancelToken,
          onSendProgress: progress,
        );
        return;
      }
      final form = FormData.fromMap({
        ...ticket.fields,
        'file': MultipartFile.fromBytes(
          file.bytes,
          filename: file.name,
          contentType: DioMediaType.parse(file.contentType),
        ),
      });
      await _dio.post<Object?>(ticket.url, data: form, cancelToken: cancelToken, onSendProgress: progress);
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  static ApiFailure _failure(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiFailure.timeout();
      case DioExceptionType.badResponse:
        final body = error.response?.data;
        final code = body is Map<String, dynamic> ? body['code'] : null;
        return ApiFailure(
          statusCode: error.response?.statusCode ?? 0,
          code: code is String ? code : refused,
          message: 'The store refused the file',
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiFailure.network();
    }
  }

  /// The code when the store refuses without saying why.
  static const refused = 'UPLOAD_REFUSED';
}
