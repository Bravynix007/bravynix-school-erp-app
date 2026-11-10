import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/files/data/file_models.dart';
import 'package:bravynix_school_erp/features/files/data/object_uploader.dart';
import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:bravynix_school_erp/features/files/domain/uploaded_file.dart';

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
  }) async {
    final grant = await _api.data(
      'files/uploads',
      method: HttpMethod.post,
      body: FileModels.requestBody(file, purpose: purpose, institutionId: institutionId),
      parse: FileModels.grant,
    );
    await _uploader.send(grant.ticket, file, onProgress: onProgress);
    return await _api.data(
      'files/${Uri.encodeComponent(grant.fileId)}/confirm',
      method: HttpMethod.post,
      parse: FileModels.uploaded,
    );
  }
}
