import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FakeReply = ({int status, Object? body, Map<String, String> headers});

FakeReply okReply(Object? data, {String code = 'OK', int status = 200}) => (
  status: status,
  body: {
    'success': true,
    'statusCode': status,
    'code': code,
    'message': 'OK',
    'data': data,
    'meta': null,
    'requestId': 'req-1',
  },
  headers: const {},
);

FakeReply errorReply(
  int status,
  String code, {
  Map<String, Object?> extra = const {},
  Map<String, String> headers = const {},
}) => (
  status: status,
  body: {
    'success': false,
    'statusCode': status,
    'code': code,
    'message': code,
    'data': null,
    'meta': null,
    'requestId': 'req-2',
    ...extra,
  },
  headers: headers,
);

/// A Dio adapter that answers from a handler and records every request.
class FakeHttpAdapter implements HttpClientAdapter {
  new(this.handler);

  final Future<FakeReply> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  List<String> get paths => [for (final request in requests) request.uri.path];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = await handler(options);
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final entry in reply.headers.entries) entry.key: [entry.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> bodyOf(RequestOptions options) => options.data! as Map<String, Object?>;
