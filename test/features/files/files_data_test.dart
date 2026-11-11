import 'dart:async';
import 'dart:typed_data';

import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/files/data/file_models.dart';
import 'package:bravynix_school_erp/features/files/data/files_repository_impl.dart';
import 'package:bravynix_school_erp/features/files/data/object_uploader.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/files.dart';

const _store = 'store.test';

/// Answers the store from [storeReply] and the API from [apiReply]; the two share one adapter, as the tests of every
/// repository do, and a request tells them apart by its host.
class _Adapter extends FakeHttpAdapter {
  new({required this.apiReply, required this.storeReply})
    : super((options) => options.uri.host == _store ? storeReply(options) : apiReply(options));

  final Future<FakeReply> Function(RequestOptions options) apiReply;
  final Future<FakeReply> Function(RequestOptions options) storeReply;
}

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');
  const storeOk = (status: 204, body: null, headers: <String, String>{});

  ({FilesRepositoryImpl repository, _Adapter adapter}) build({
    Future<FakeReply> Function(RequestOptions options)? api,
    Future<FakeReply> Function(RequestOptions options)? store,
  }) {
    final adapter = _Adapter(
      apiReply:
          api ??
          (options) async =>
              options.uri.path.endsWith('/confirm') ? okReply(confirmedJson()) : okReply(grantJson(), status: 201),
      storeReply: store ?? (_) async => storeOk,
    );
    final client = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (
      repository: FilesRepositoryImpl(
        api: client,
        uploader: ObjectUploader(ObjectUploader.createDio(adapter: adapter)),
      ),
      adapter: adapter,
    );
  }

  group('FIL-03', () {
    test('asks for the link of a file and gives back its address, encoding the ID', () async {
      final (:repository, :adapter) = build(
        api: (_) async =>
            okReply({'url': 'http://store.test/v1/get/token?sig=1', 'expiresAt': '2026-11-10T05:05:00.000Z'}),
      );
      final link = await repository.downloadLink('f/1');
      expect(link, Uri.parse('http://store.test/v1/get/token?sig=1'));
      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.uri.path, '/v1/files/f%2F1/download');
    });

    test('says why when the file cannot be read', () async {
      final (:repository, adapter: _) = build(api: (_) async => errorReply(404, 'NOT_FOUND'));
      await expectLater(
        repository.downloadLink('f1'),
        throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', 'NOT_FOUND')),
      );
    });
  });

  group('models', () {
    test('read the ticket of FIL-01 and the file of FIL-02, ignoring what they do not show', () {
      final grant = FileModels.grant(grantJson());
      expect(grant.fileId, 'f1');
      expect(grant.ticket.url, 'http://store.test/v1/local-storage/token');
      expect(grant.ticket.fields, {'key': 'k1', 'policy': 'p1'});
      expect(FileModels.uploaded(confirmedJson()), uploadedPhoto);
    });

    test('refuse an answer they cannot read instead of sending a file to nowhere', () {
      expect(() => FileModels.grant('x'), throwsFormatException);
      expect(() => FileModels.grant({'fileId': 'f1'}), throwsFormatException);
      expect(() => FileModels.uploaded({...confirmedJson(), 'sizeBytes': null}), throwsA(isA<TypeError>()));
    });

    test('ask for the purpose by its number, with the size and type of the file', () {
      expect(FileModels.requestBody(photo, purpose: FilePurpose.staffPhoto, institutionId: 'i1'), {
        'purpose': 4,
        'institutionId': 'i1',
        'contentType': 'image/png',
        'sizeBytes': photo.sizeBytes,
        'fileName': 'kavya.png',
      });
    });
  });

  group('FIL-01, the store and FIL-02', () {
    test('ask, send, then confirm, and give back the Ready file', () async {
      final (:repository, :adapter) = build();
      final uploaded = await repository.upload(photo, purpose: FilePurpose.staffPhoto, institutionId: 'i1');
      expect(uploaded, uploadedPhoto);
      expect(adapter.paths, ['/v1/files/uploads', '/v1/local-storage/token', '/v1/files/f1/confirm']);
      expect(adapter.requests.map((request) => request.method), ['POST', 'POST', 'POST']);
      expect(adapter.requests.first.data, {
        'purpose': 4,
        'institutionId': 'i1',
        'contentType': 'image/png',
        'sizeBytes': photo.sizeBytes,
        'fileName': 'kavya.png',
      });
    });

    test('send the file to the store as a form with the ticket fields first, and no sign-in', () async {
      final (:repository, :adapter) = build();
      await repository.upload(photo, purpose: FilePurpose.staffPhoto, institutionId: 'i1');
      final sent = adapter.requests[1];
      expect(sent.headers.keys.map((key) => key.toLowerCase()), isNot(contains('authorization')));
      expect(sent.headers.keys.map((key) => key.toLowerCase()), isNot(contains('x-device-platform')));
      final form = sent.data! as FormData;
      expect(form.fields.map((field) => '${field.key}=${field.value}'), ['key=k1', 'policy=p1']);
      // S3 ignores a field that comes after the file (API design 15.1), so the order on the wire is what counts.
      final onTheWire = String.fromCharCodes(await form.clone().finalize().expand((chunk) => chunk).toList());
      expect(onTheWire.indexOf('name="key"'), isNonNegative);
      expect(onTheWire.indexOf('name="key"'), lessThan(onTheWire.indexOf('name="policy"')));
      expect(onTheWire.indexOf('name="policy"'), lessThan(onTheWire.indexOf('name="file"')));
      expect(form.files.single.key, 'file');
      expect(form.files.single.value.filename, 'kavya.png');
      expect(form.files.single.value.contentType.toString(), 'image/png');
      // The API call carries the sign-in; the store call does not.
      expect(adapter.requests.first.headers['Authorization'], 'Bearer a1');
    });

    test('tell the screen how much has been sent', () async {
      final adapter = _Adapter(
        apiReply: (options) async =>
            options.uri.path.endsWith('/confirm') ? okReply(confirmedJson()) : okReply(grantJson(), status: 201),
        storeReply: (_) async => storeOk,
      );
      // Reading the body, as the real adapter does, is what reports progress.
      final reading = _ReadingAdapter(adapter);
      final client = createApiClient(
        config: config,
        device: device,
        tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
        events: ApiEvents(),
        language: () => 'en',
        adapter: adapter,
      );
      final repository = FilesRepositoryImpl(
        api: client,
        uploader: ObjectUploader(ObjectUploader.createDio(adapter: reading)),
      );
      final seen = <double>[];
      await repository.upload(
        photo,
        purpose: FilePurpose.staffPhoto,
        institutionId: 'i1',
        onProgress: seen.add,
      );
      expect(seen, isNotEmpty);
      expect(seen.last, 1);
      expect(seen, orderedEquals([...seen]..sort()));
    });

    test('stop at the first refusal and say which one it was', () async {
      for (final (status, code) in [
        (403, 'FORBIDDEN'),
        (404, 'NOT_FOUND'),
        (413, 'FILE_TOO_LARGE'),
        (415, 'FILE_TYPE_NOT_ALLOWED'),
      ]) {
        final (:repository, :adapter) = build(api: (_) async => errorReply(status, code));
        await expectLater(
          repository.upload(photo, purpose: FilePurpose.staffPhoto, institutionId: 'i1'),
          throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', code)),
        );
        // Nothing was sent to the store.
        expect(adapter.paths, ['/v1/files/uploads']);
      }
    });

    test('say so when the server finds the file is not what it said, or never arrived', () async {
      for (final code in ['FILE_CHECK_FAILED', 'UPLOAD_NOT_FOUND']) {
        final (:repository, adapter: _) = build(
          api: (options) async =>
              options.uri.path.endsWith('/confirm') ? errorReply(422, code) : okReply(grantJson(), status: 201),
        );
        await expectLater(
          repository.upload(photo, purpose: FilePurpose.staffPhoto, institutionId: 'i1'),
          throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', code)),
        );
      }
    });

    group('when the screen goes', () {
      test('send nothing when it was cancelled before FIL-01', () async {
        final token = CancelToken()..cancel();
        final (:repository, :adapter) = build();
        await expectLater(
          repository.upload(photo, purpose: FilePurpose.staffPhoto, institutionId: 'i1', cancelToken: token),
          throwsA(isA<ApiFailure>()),
        );
        expect(adapter.paths, isEmpty);
      });

      test(
        'carry the token on FIL-01, the send to the store and FIL-02, so a cancel stops whichever is going',
        () async {
          final token = CancelToken();
          final (:repository, :adapter) = build();
          await repository.upload(photo, purpose: FilePurpose.staffPhoto, institutionId: 'i1', cancelToken: token);
          expect(adapter.paths, ['/v1/files/uploads', '/v1/local-storage/token', '/v1/files/f1/confirm']);
          expect([for (final request in adapter.requests) request.cancelToken], everyElement(same(token)));
        },
      );

      test('stop a send to the store that a cancel interrupts, and never confirm it', () async {
        final token = CancelToken();
        final (:repository, :adapter) = build(
          store: (_) async {
            token.cancel();
            return storeOk;
          },
        );
        await expectLater(
          repository.upload(photo, purpose: FilePurpose.staffPhoto, institutionId: 'i1', cancelToken: token),
          throwsA(isA<ApiFailure>()),
        );
        expect(adapter.paths, ['/v1/files/uploads', '/v1/local-storage/token']);
      });
    });

    test('never confirm a file the store refused', () async {
      final (:repository, :adapter) = build(
        store: (_) async => errorReply(400, 'BAD_UPLOAD'),
      );
      await expectLater(
        repository.upload(photo, purpose: FilePurpose.staffPhoto, institutionId: 'i1'),
        throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', 'BAD_UPLOAD')),
      );
      expect(adapter.paths, ['/v1/files/uploads', '/v1/local-storage/token']);
    });
  });

  group('the store refuses', () {
    Future<ApiFailure> failureOf(FakeReply Function() reply) async {
      final (:repository, adapter: _) = build(store: (_) async => reply());
      try {
        await repository.upload(photo, purpose: FilePurpose.staffPhoto, institutionId: 'i1');
      } on ApiFailure catch (failure) {
        return failure;
      }
      fail('expected a refusal');
    }

    test('with its own code when it gives one, and UPLOAD_REFUSED when it does not', () async {
      final bad = await failureOf(() => errorReply(400, 'BAD_UPLOAD'));
      expect([bad.statusCode, bad.code], [400, 'BAD_UPLOAD']);
      final taken = await failureOf(() => errorReply(409, 'ALREADY_UPLOADED'));
      expect(taken.code, 'ALREADY_UPLOADED');
      final expired = await failureOf(() => (status: 403, body: 'denied', headers: const {}));
      expect([expired.statusCode, expired.code], [403, ObjectUploader.refused]);
    });
  });

  group('the network', () {
    Future<ApiFailure> failureOf(DioExceptionType type) async {
      final dio = ObjectUploader.createDio(adapter: _Throwing(type));
      try {
        await ObjectUploader(dio).send(FileModels.grant(grantJson()).ticket, photo);
      } on ApiFailure catch (failure) {
        return failure;
      }
      fail('expected a failure');
    }

    test('says it took too long for every kind of timeout', () async {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect((await failureOf(type)).code, ApiFailure.timeoutError);
      }
    });

    test('says it cannot reach the store for the rest', () async {
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.badCertificate,
        DioExceptionType.unknown,
      ]) {
        expect((await failureOf(type)).code, ApiFailure.networkError);
      }
    });
  });
}

/// Reads the whole request body, so Dio reports the bytes sent as the real adapter does.
class _ReadingAdapter implements HttpClientAdapter {
  new(this._inner);

  final HttpClientAdapter _inner;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) await requestStream.drain<void>();
    return await _inner.fetch(options, null, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}

class _Throwing implements HttpClientAdapter {
  const new(this.type);

  final DioExceptionType type;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) =>
      Future.error(DioException(requestOptions: options, type: type));

  @override
  void close({bool force = false}) {}
}
