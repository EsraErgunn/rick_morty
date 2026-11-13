import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';
import '../logging/app_logger.dart';
import 'endpoints.dart';
import 'retry_interceptor.dart';

/// Rick and Morty API'si için ince Dio sarmalayıcısı. Asla hata fırlatmaz: her çağrı
/// `Either<Failure, T>` döndürür.
class ApiClient {
  /// HTTPS olmayan bir [baseUrl] için [ArgumentError] fırlatır (release'de de).
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

  /// İstek aşaması başına (mimari kurallar).
  static const Duration timeout = Duration(seconds: 15);

  final Dio _dio;

  static String _requireHttps(String url) {
    if (Uri.tryParse(url)?.scheme != 'https') {
      throw ArgumentError.value(url, 'baseUrl', 'must use https');
    }
    return url;
  }

  /// [path] adresine GET yapar ve JSON nesne gövdesini döndürür.
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
        // Soket ve TLS sorunları (ağ yok, HTTPS'i yeniden imzalayan bir proxy)
        // oyuncu için bağlantı sorunudur.
        return e.error is IOException
            ? NetworkFailure('${e.error.runtimeType}')
            : UnexpectedFailure(e.type.name);
      case DioExceptionType.cancel:
        return UnexpectedFailure(e.type.name);
    }
  }

  void close() => _dio.close(force: true);
}
