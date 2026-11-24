import 'dart:io';

import 'package:mocktail/mocktail.dart';

import 'files.dart';

class _Client extends Mock implements HttpClient;

class _Request extends Mock implements HttpClientRequest;

class _Response extends Mock implements HttpClientResponse;

class _Headers extends Mock implements HttpHeaders;

/// Runs [body] with every picture address answering the 1x1 PNG of [photo], so a screen that shows a picture by its
/// address can be built without a network. Tests never touch the network (CLAUDE.md). With [status] other than 200 every
/// address is refused with it, as for a picture that has been removed.
Future<T> withNetworkImages<T>(Future<T> Function() body, {int status = HttpStatus.ok}) =>
    HttpOverrides.runZoned(body, createHttpClient: (_) => _client(status));

HttpClient _client(int status) {
  registerFallbackValue(Uri());
  final bytes = photo.bytes;
  final client = _Client();
  final request = _Request();
  final response = _Response();
  when(() => client.getUrl(any())).thenAnswer((_) async => request);
  when(() => client.autoUncompress = any()).thenReturn(true);
  when(() => request.headers).thenReturn(_Headers());
  when(request.close).thenAnswer((_) async => response);
  when(() => response.statusCode).thenReturn(status);
  when(() => response.contentLength).thenReturn(bytes.length);
  when(() => response.compressionState).thenReturn(HttpClientResponseCompressionState.notCompressed);
  when(
    () => response.listen(
      any(),
      onError: any(named: 'onError'),
      onDone: any(named: 'onDone'),
      cancelOnError: any(named: 'cancelOnError'),
    ),
  ).thenAnswer((call) {
    final onData = call.positionalArguments.first as void Function(List<int>);
    final onDone = call.namedArguments[#onDone] as void Function()?;
    return Stream<List<int>>.fromIterable([bytes]).listen(onData, onDone: onDone);
  });
  return client;
}
