import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';
import '../logging/app_logger.dart';
import 'endpoints.dart';
import 'retry_interceptor.dart';

/// Thin Dio wrapper for the Rick and Morty API. Never throws: every call
/// returns `Either<Failure, T>`.
class ApiClient {
  /// Throws [ArgumentError] for a non-HTTPS [baseUrl] (also in release).
  ApiClient({
    String baseUrl = Endpoints.baseUrl,
    HttpClientAdapter? adapter,
    Sleep? sleep,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: _requireHttps(baseUrl),
           connectTimeout: timeout,
           sendTimeout: timeout,
           receiveTimeout: timeout,
           responseType: ResponseType.json,
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
    _dio.interceptors.add(
      sleep == null
          ? RetryInterceptor(dio: _dio)
          : RetryInterceptor(dio: _dio, sleep: sleep),
    );
  }

  /// Per request phase (architecture rules).
  static const Duration timeout = Duration(seconds: 15);

  final Dio _dio;

  static String _requireHttps(String url) {
    if (Uri.tryParse(url)?.scheme != 'https') {
      throw ArgumentError.value(url, 'baseUrl', 'must use https');
    }
    return url;
  }

  /// GET [path] and return the JSON object body.
  Future<Either<Failure, Map<String, dynamic>>> getJson(
    String path, {
    Map<String, Object>? query,
  }) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: query);
      final data = response.data;
      if (data is Map<String, dynamic>) return right(data);
      return left(ParseFailure('expected a JSON object from $path'));
    } on DioException catch (e) {
      final failure = mapDioException(e);
      AppLogger.warning('GET $path failed: ${failure.runtimeType}');
      return left(failure);
    }
  }

  static Failure mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutFailure();
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return NetworkFailure(e.type.name);
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        return status == 429 || status >= 500
            ? ServerFailure(status)
            : ClientFailure(status);
      case DioExceptionType.unknown:
        // Socket and TLS problems (no network, a proxy re-signing HTTPS)
        // are connection problems for the player.
        return e.error is IOException
            ? NetworkFailure('${e.error.runtimeType}')
            : UnexpectedFailure(e.type.name);
      case DioExceptionType.cancel:
        return UnexpectedFailure(e.type.name);
    }
  }

  void close() => _dio.close(force: true);
}
