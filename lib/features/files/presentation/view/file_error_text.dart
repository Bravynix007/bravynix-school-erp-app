import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/features/files/domain/file_check.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// Why the app refused a file before sending it.
String fileProblemText(AppLocalizations l10n, FileProblem problem) => switch (problem) {
  FileProblem.empty => l10n.errorFileEmpty,
  FileProblem.tooLarge => l10n.errorFileTooLarge,
  FileProblem.typeNotAllowed => l10n.errorFileTypeNotAllowed,
};

/// Copy for the codes the upload flow adds (API design 15.1): 413 `FILE_TOO_LARGE`, 415 `FILE_TYPE_NOT_ALLOWED`, 422
/// `FILE_CHECK_FAILED` and `UPLOAD_NOT_FOUND`, the store's refusal, and 404 for a school the caller does not reach;
/// the rest reads as everywhere else.
String fileErrorText(AppLocalizations l10n, ApiFailure failure) => switch (failure.code) {
  'FILE_TOO_LARGE' => l10n.errorFileTooLarge,
  'FILE_TYPE_NOT_ALLOWED' => l10n.errorFileTypeNotAllowed,
  'FILE_CHECK_FAILED' => l10n.errorFileCheckFailed,
  'UPLOAD_NOT_FOUND' => l10n.errorFileNotArrived,
  'UPLOAD_REFUSED' || 'BAD_UPLOAD' || 'ALREADY_UPLOADED' => l10n.errorFileRefused,
  _ => apiErrorText(l10n, failure, notFound: l10n.errorFileSchoolNotFound),
};

/// Why the phone would not give a file.
String filePickFailureText(AppLocalizations l10n, FilePickFailure failure) => switch (failure.source) {
  PhotoSource.camera => l10n.errorFilePickCamera,
  PhotoSource.gallery => l10n.errorFilePickGallery,
  null => l10n.errorFilePickFiles,
};
