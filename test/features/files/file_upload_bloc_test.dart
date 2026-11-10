import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/files/domain/file_check.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/presentation/bloc/file_upload_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/files.dart';
import '../../helpers/mocks.dart';

const _refused = ApiFailure(statusCode: 415, code: 'FILE_TYPE_NOT_ALLOWED', message: 'server words');
const _offline = ApiFailure.network();

void main() {
  late MockFilesRepository files;
  setUp(() => files = MockFilesRepository());
  setUpAll(() {
    registerFallbackValue(photo);
    registerFallbackValue(FilePurpose.staffPhoto);
  });

  FileUploadBloc build({FilePurpose purpose = FilePurpose.staffPhoto}) =>
      FileUploadBloc(files, purpose: purpose, institutionId: 'i1');

  When<Future<dynamic>> upload() => when(
    () => files.upload(
      any(),
      purpose: any(named: 'purpose'),
      institutionId: any(named: 'institutionId'),
      onProgress: any(named: 'onProgress'),
    ),
  );

  Future<dynamic> Function(Invocation) sendsAndReports(List<double> shares) => (invocation) async {
    final onProgress = invocation.namedArguments[#onProgress] as void Function(double)?;
    for (final share in shares) {
      onProgress?.call(share);
      await Future<void>.delayed(Duration.zero);
    }
    return uploadedPhoto;
  };

  blocTest<FileUploadBloc, FileUploadState>(
    'sends a good file for its purpose and Institution, with the progress the repository reports',
    setUp: () => upload().thenAnswer(sendsAndReports([0.5, 1])),
    build: build,
    act: (bloc) => bloc.add(FileUploadStarted(photo)),
    wait: const Duration(milliseconds: 20),
    expect: () => [
      FileUploadSending(photo),
      FileUploadSending(photo, sent: 0.5),
      FileUploadSending(photo, sent: 1),
      FileUploadDone(photo, uploadedPhoto),
    ],
    verify: (_) => verify(
      () => files.upload(
        photo,
        purpose: FilePurpose.staffPhoto,
        institutionId: 'i1',
        onProgress: any(named: 'onProgress'),
      ),
    ).called(1),
  );

  blocTest<FileUploadBloc, FileUploadState>(
    'does not send a file the server would refuse, and says why',
    build: build,
    act: (bloc) => bloc.add(FileUploadStarted(pdf)),
    expect: () => [FileUploadFailed(pdf, problem: FileProblem.typeNotAllowed)],
    verify: (_) => verifyNever(
      () => files.upload(
        any(),
        purpose: any(named: 'purpose'),
        institutionId: any(named: 'institutionId'),
        onProgress: any(named: 'onProgress'),
      ),
    ),
  );

  blocTest<FileUploadBloc, FileUploadState>(
    'fails with the reason the server gave',
    setUp: () => upload().thenThrow(_refused),
    build: build,
    act: (bloc) => bloc.add(FileUploadStarted(photo)),
    expect: () => [FileUploadSending(photo), FileUploadFailed(photo, failure: _refused)],
  );

  blocTest<FileUploadBloc, FileUploadState>(
    'sends the same file again after a failure that may pass, and is done',
    setUp: () {
      var calls = 0;
      upload().thenAnswer((_) async {
        calls++;
        if (calls == 1) throw _offline;
        return uploadedPhoto;
      });
    },
    build: build,
    act: (bloc) async {
      bloc.add(FileUploadStarted(photo));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const FileUploadRetried());
    },
    expect: () => [
      FileUploadSending(photo),
      FileUploadFailed(photo, failure: _offline),
      FileUploadSending(photo),
      FileUploadDone(photo, uploadedPhoto),
    ],
  );

  blocTest<FileUploadBloc, FileUploadState>(
    'cannot retry a file the app refused: it has to be replaced',
    build: build,
    seed: () => FileUploadFailed(pdf, problem: FileProblem.tooLarge),
    act: (bloc) => bloc.add(const FileUploadRetried()),
    expect: () => <FileUploadState>[],
  );

  blocTest<FileUploadBloc, FileUploadState>(
    'ignores a second file while one is going',
    setUp: () {
      final gate = Completer<void>();
      upload().thenAnswer((_) async {
        await gate.future;
        return uploadedPhoto;
      });
      addTearDown(gate.complete);
    },
    build: build,
    act: (bloc) async {
      bloc.add(FileUploadStarted(photo));
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(FileUploadStarted(pdf))
        ..add(const FileUploadCleared());
    },
    expect: () => [FileUploadSending(photo)],
    verify: (_) => verify(
      () => files.upload(
        any(),
        purpose: any(named: 'purpose'),
        institutionId: any(named: 'institutionId'),
        onProgress: any(named: 'onProgress'),
      ),
    ).called(1),
  );

  blocTest<FileUploadBloc, FileUploadState>(
    'forgets a sent file, a failed one and a refused one when cleared, and takes a new one after',
    setUp: () => upload().thenAnswer((_) async => uploadedPhoto),
    build: build,
    seed: () => FileUploadFailed(pdf, problem: FileProblem.typeNotAllowed),
    act: (bloc) async {
      bloc.add(const FileUploadCleared());
      await Future<void>.delayed(Duration.zero);
      bloc.add(FileUploadStarted(photo));
    },
    expect: () => [const FileUploadIdle(), FileUploadSending(photo), FileUploadDone(photo, uploadedPhoto)],
  );

  blocTest<FileUploadBloc, FileUploadState>(
    'lets a sent photo be replaced by another',
    setUp: () => upload().thenAnswer((_) async => uploadedPhoto),
    build: build,
    seed: () => FileUploadDone(photo, uploadedPhoto),
    act: (bloc) => bloc.add(FileUploadStarted(photo)),
    expect: () => [FileUploadSending(photo), FileUploadDone(photo, uploadedPhoto)],
  );

  test('a failure either names a problem or a failure, and only a failure can be retried', () {
    expect(FileUploadFailed(photo, failure: _offline).canRetry, isTrue);
    expect(FileUploadFailed(photo, problem: FileProblem.empty).canRetry, isFalse);
    expect(() => FileUploadFailed(photo), throwsAssertionError);
  });
}
