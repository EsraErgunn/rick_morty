import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Senaryolu tek bir yanıt: bir durum + JSON gövde ya da fırlatılan bir [DioExceptionType].
class FakeReply {
  const FakeReply(this.status, [this.body = const {}, this.headers = const {}])
    : error = null;

  const FakeReply.error(DioExceptionType this.error)
    : status = 0,
      body = null,
      headers = const {};

  final int status;
  final Object? body;
  final Map<String, List<String>> headers;
  final DioExceptionType? error;
}

/// [replies] yanıtlarını sırayla tekrarlayan (sonuncusu tekrar eder) ve istenen her URI'yi
/// kaydeden [HttpClientAdapter].
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.replies);

  /// Yol + sorguya göre cevaplar, ör. `'/character?page=2'`.
  FakeAdapter.byRoute(this.routes) : replies = const [];

  final List<FakeReply> replies;
  Map<String, List<FakeReply>> routes = {};
  final List<Uri> requests = [];

  int get calls => requests.length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    final reply = _next(options.uri);
    if (reply.error != null) {
      throw DioException(requestOptions: options, type: reply.error!);
    }
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...reply.headers,
      },
    );
  }

  FakeReply _next(Uri uri) {
    if (routes.isNotEmpty) {
      final key = uri.query.isEmpty ? uri.path : '${uri.path}?${uri.query}';
      final match = routes.entries.firstWhere(
        (e) => key.endsWith(e.key),
        orElse: () => throw StateError('no fake route for $key'),
      );
      final queue = match.value;
      return queue.length > 1 ? queue.removeAt(0) : queue.first;
    }
    final index = requests.length - 1;
    return replies[index < replies.length ? index : replies.length - 1];
  }

  @override
  void close({bool force = false}) {}
}
