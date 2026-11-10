import 'dart:ui';

import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/files/domain/file_check.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/presentation/view/file_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  String text(int status, String code) =>
      fileErrorText(l10n, ApiFailure(statusCode: status, code: code, message: 'server words'));

  test("says in the app's own words what each refusal of the upload flow means", () {
    expect(text(413, 'FILE_TOO_LARGE'), 'This file is larger than 5 MB. Choose a smaller one.');
    expect(text(415, 'FILE_TYPE_NOT_ALLOWED'), "This kind of file can't be used here. Choose a different one.");
    expect(
      text(422, 'FILE_CHECK_FAILED'),
      'The file is damaged or is not what it says it is. Choose it again.',
    );
    expect(text(422, 'UPLOAD_NOT_FOUND'), 'The file did not arrive. Send it again.');
    expect(text(403, 'FORBIDDEN'), "You don't have access to this.");
    expect(text(404, 'NOT_FOUND'), "You can't add files for this school.");
  });

  test('says the file could not be sent for every refusal of the store, whatever it called it', () {
    for (final code in ['UPLOAD_REFUSED', 'BAD_UPLOAD', 'ALREADY_UPLOADED']) {
      expect(text(400, code), 'The file could not be sent. Send it again.');
    }
  });

  test('reads the network and the rest as everywhere else', () {
    expect(fileErrorText(l10n, const ApiFailure.network()), l10n.errorNetwork);
    expect(text(400, 'VALIDATION_FAILED'), 'Check the fields marked in red.');
  });

  test('says why a file was refused before it was sent', () {
    expect(fileProblemText(l10n, FileProblem.empty), 'This file is empty. Choose another one.');
    expect(fileProblemText(l10n, FileProblem.tooLarge), text(413, 'FILE_TOO_LARGE'));
    expect(fileProblemText(l10n, FileProblem.typeNotAllowed), text(415, 'FILE_TYPE_NOT_ALLOWED'));
  });

  test('says what the phone could not open', () {
    expect(filePickFailureText(l10n, const FilePickFailure(PhotoSource.camera)), contains('camera'));
    expect(filePickFailureText(l10n, const FilePickFailure(PhotoSource.gallery)), contains('photos'));
    expect(filePickFailureText(l10n, const FilePickFailure(null)), contains('files'));
  });
}
