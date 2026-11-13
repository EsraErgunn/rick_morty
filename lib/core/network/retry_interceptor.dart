import 'dart:math';

import 'package:dio/dio.dart';

import '../logging/app_logger.dart';

/// [duration] kadar bekler. Testler uyumasın diye enjekte edilir.
typedef Sleep = Future<void> Function(Duration duration);

Future<void> _realSleep(Duration duration) => Future<void>.delayed(duration);

/// 429, 5xx, zaman aşımı ve bağlantı hatalarını üstel geri çekilmeyle tekrar dener
/// (mimari kurallar: en fazla 3 deneme). Diğer 4xx'ler asla tekrar denenmez.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this._dio,
    this.maxRetries = defaultMaxRetries,
    this.baseDelay = defaultBaseDelay,
    this._sleep = _realSleep,
  });

  static const int defaultMaxRetries = 3;
  static const Duration defaultBaseDelay = Duration(milliseconds: 500);

  /// Sunucunun gönderdiği `Retry-After` için üst sınır.
  static const Duration maxRetryAfter = Duration(seconds: 10);

  static const String _attemptKey = 'retry_attempt';

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;
  final Sleep _sleep;

  static bool isRetryable(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => true,
    DioExceptionType.badResponse => _isRetryableStatus(e.response?.statusCode),
    DioExceptionType.transformTimeout ||
    DioExceptionType.badCertificate ||
    DioExceptionType.cancel ||
    DioExceptionType.unknown => false,
  };

  static bool _isRetryableStatus(int? status) =>
      status != null && (status == 429 || status >= 500);

  /// 500 ms, 1 sn, 2 sn, ... ya da sunucunun `Retry-After` değeri (sınırlı).
  Duration delayFor(int attempt, Response<dynamic>? response) {
    final retryAfter = int.tryParse(
      response?.headers.value('retry-after') ?? '',
    );
    if (retryAfter != null && retryAfter >= 0) {
      final asked = Duration(seconds: retryAfter);
      return asked > maxRetryAfter ? maxRetryAfter : asked;
    }
    return baseDelay * pow(2, attempt).toInt();
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (!isRetryable(err) || attempt >= maxRetries) {
      handler.next(err);
      return;
    }

    final delay = delayFor(attempt, err.response);
    AppLogger.warning(
      'retry ${attempt + 1}/$maxRetries ${options.path} '
      '(${err.response?.statusCode ?? err.type.name}) in ${delay.inMilliseconds} ms',
    );
    await _sleep(delay);

    options.extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
