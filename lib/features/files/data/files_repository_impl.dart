import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/files/data/file_models.dart';
import 'package:bravynix_school_erp/features/files/data/object_uploader.dart';
import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:bravynix_school_erp/features/files/domain/uploaded_file.dart';
import 'package:dio/dio.dart' show CancelToken;

class FilesRepositoryImpl implements FilesRepository {
  const new({required this._api, required this._uploader});

  final ApiClient _api;
  final ObjectUploader _uploader;

  @override
  Future<UploadedFile> upload(
    ChosenFile file, {
    required FilePurpose purpose,
    required String institutionId,
    void Function(double sent)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final grant = (await _api.request(
      'files/uploads',
      method: HttpMethod.post,
      body: FileModels.requestBody(file, purpose: purpose, institutionId: institutionId),
      cancelToken: cancelToken,
      parse: FileModels.grant,
    )).data;
    await _uploader.send(grant.ticket, file, onProgress: onProgress, cancelToken: cancelToken);
    return (await _api.request(
      'files/${Uri.encodeComponent(grant.fileId)}/confirm',
      method: HttpMethod.post,
      cancelToken: cancelToken,
      parse: FileModels.uploaded,
    )).data;
  }
}
