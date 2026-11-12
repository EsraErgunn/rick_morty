import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/core/network/dio_client.dart';
import 'package:portalcards/core/network/endpoints.dart';
import 'package:portalcards/core/network/retry_interceptor.dart';

import 'fake_adapter.dart';

void main() {
  late List<Duration> slept;
  Future<void> fakeSleep(Duration d) async => slept.add(d);

  setUp(() => slept = []);

  ApiClient client(FakeAdapter adapter) =>
      ApiClient(adapter: adapter, sleep: fakeSleep);

  group('retries', () {
    test(
      '2x 503 then 200: success after 3 calls with 500 ms, 1 s backoff',
      () async {
        final adapter = FakeAdapter([
          const FakeReply(503),
          const FakeReply(503),
          const FakeReply(200, {'ok': true}),
        ]);

        final result = await client(adapter).getJson(Endpoints.characters);

        expect(result.getRight().toNullable(), {'ok': true});
        expect(adapter.calls, 3);
        expect(slept, [
          const Duration(milliseconds: 500),
          const Duration(seconds: 1),
        ]);
      },
    );

    test('4x 503: ServerFailure after 1 call + 3 retries', () async {
      final adapter = FakeAdapter([const FakeReply(503)]);

      final result = await client(adapter).getJson(Endpoints.characters);

      expect(
        result,
        left<Failure, Map<String, dynamic>>(const ServerFailure(503)),
      );
      expect(adapter.calls, 4);
      expect(slept, hasLength(3));
    });

    test('429 is retried and honors Retry-After', () async {
      final adapter = FakeAdapter([
        const FakeReply(429, {}, {
          'retry-after': ['2'],
        }),
        const FakeReply(200, {'ok': true}),
      ]);

      final result = await client(adapter).getJson(Endpoints.episodes);

      expect(result.isRight(), isTrue);
      expect(slept, [const Duration(seconds: 2)]);
    });

    test('Retry-After is capped at 10 s', () async {
      final adapter = FakeAdapter([
        const FakeReply(429, {}, {
          'retry-after': ['3600'],
        }),
        const FakeReply(200, {}),
      ]);

      await client(adapter).getJson(Endpoints.episodes);

      expect(slept, [RetryInterceptor.maxRetryAfter]);
    });

    test('404: no retry, ClientFailure', () async {
      final adapter = FakeAdapter([
        const FakeReply(404, {'error': 'x'}),
      ]);

      final result = await client(adapter).getJson('/character/99999');

      expect(
        result,
        left<Failure, Map<String, dynamic>>(const ClientFailure(404)),
      );
      expect(adapter.calls, 1);
      expect(slept, isEmpty);
    });

    test(
      'receive timeout on every try: TimeoutFailure after 4 calls',
      () async {
        final adapter = FakeAdapter([
          const FakeReply.error(DioExceptionType.receiveTimeout),
        ]);

        final result = await client(adapter).getJson(Endpoints.locations);

        expect(
          result,
          left<Failure, Map<String, dynamic>>(const TimeoutFailure()),
        );
        expect(adapter.calls, 4);
      },
    );

    test('connection error then 200: recovers', () async {
      final adapter = FakeAdapter([
        const FakeReply.error(DioExceptionType.connectionError),
        const FakeReply(200, {'ok': 1}),
      ]);

      final result = await client(adapter).getJson(Endpoints.locations);

      expect(result.isRight(), isTrue);
      expect(adapter.calls, 2);
    });

    test('connection error on every try: NetworkFailure', () async {
      final adapter = FakeAdapter([
        const FakeReply.error(DioExceptionType.connectionError),
      ]);

      final result = await client(adapter).getJson(Endpoints.locations);

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });
  });

  group('ApiClient', () {
    test('rejects a non-HTTPS base URL', () {
      expect(
        () => ApiClient(baseUrl: 'http://rickandmortyapi.com/api'),
        throwsArgumentError,
      );
    });

    test('uses the HTTPS API base URL and 15 s timeouts by default', () {
      expect(Endpoints.baseUrl, startsWith('https://'));
      expect(ApiClient.timeout, const Duration(seconds: 15));
    });

    test('sends the page query', () async {
      final adapter = FakeAdapter([const FakeReply(200, {})]);

      await client(adapter)
          .getJson(Endpoints.characters, query: Endpoints.page(3));

      expect(
        adapter.requests.single.toString(),
        'https://rickandmortyapi.com/api/character?page=3',
      );
    });

    test('a JSON array body is a ParseFailure, not a crash', () async {
      final adapter = FakeAdapter([
        const FakeReply(200, [1, 2]),
      ]);

      final result = await client(adapter).getJson('/character/1,2');

      expect(result.getLeft().toNullable(), isA<ParseFailure>());
    });
  });

  group('Endpoints.idFromUrl', () {
    test('extracts the id at the end of a resource URL', () {
      expect(
        Endpoints.idFromUrl('https://rickandmortyapi.com/api/character/42'),
        42,
      );
      expect(
        Endpoints.idFromUrl('https://rickandmortyapi.com/api/episode/7/'),
        7,
      );
    });

    test('returns null for URLs without an id', () {
      expect(Endpoints.idFromUrl(''), isNull);
      expect(
        Endpoints.idFromUrl('https://rickandmortyapi.com/api/location/'),
        isNull,
      );
    });
  });
}
