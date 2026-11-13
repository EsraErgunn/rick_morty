import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Log çıktısının imzası. Varsayılan `dart:developer` `log`.
typedef LogSink = void Function(
  String message, {
  required String name,
  required int level,
  Object? error,
  StackTrace? stackTrace,
});

void _developerSink(
  String message, {
  required String name,
  required int level,
  Object? error,
  StackTrace? stackTrace,
}) {
  // debugPrint logcat'e / çalıştırma konsoluna ulaşır (dart:developer `log` yalnızca
  // DevTools'a ulaşır); bu çıktı yalnızca debug derlemelerde çalışır.
  debugPrint('[$name] $message${error == null ? '' : ' | $error'}');
  developer.log(
    message,
    name: name,
    level: level,
    error: error,
    stackTrace: stackTrace,
  );
}

/// Uygulamadaki tek logger. Yalnızca debug derlemelerde yazar; release ve
/// profile'da hiçbir şey yapmaz. API verilerini veya oyuncu verilerini asla loglama (L1 kuralları).
abstract final class AppLogger {
  /// Debug dışında kapalı. Testler değiştirebilir.
  @visibleForTesting
  static bool enabled = kDebugMode;

  @visibleForTesting
  static LogSink sink = _developerSink;

  static const String _name = 'portalcards';

  // Seviyeler package:logging'i izler (dart:developer geleneği).
  static const int _debug = 500;
  static const int _info = 800;
  static const int _warning = 900;
  static const int _error = 1000;

  static void debug(String message) => _log(message, _debug);

  static void info(String message) => _log(message, _info);

  static void warning(String message, [Object? error]) =>
      _log(message, _warning, error: error);

  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(message, _error, error: error, stackTrace: stackTrace);

  static void _log(
    String message,
    int level, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enabled) return;
    sink(
      message,
      name: _name,
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Bir test değiştirdikten sonra varsayılanları geri yükler.
  @visibleForTesting
  static void reset() {
    enabled = kDebugMode;
    sink = _developerSink;
  }
}
