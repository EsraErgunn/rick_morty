import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Signature of the log output. Defaults to `dart:developer` `log`.
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
  // debugPrint reaches logcat / the run console (dart:developer `log` only
  // reaches DevTools); this sink only runs in debug builds.
  debugPrint('[$name] $message${error == null ? '' : ' | $error'}');
  developer.log(
    message,
    name: name,
    level: level,
    error: error,
    stackTrace: stackTrace,
  );
}

/// The only logger in the app. Writes in debug builds only; a no-op in
/// release and profile. Never log API payloads or player data (L1 rules).
abstract final class AppLogger {
  /// Off outside debug builds. Tests may override.
  @visibleForTesting
  static bool enabled = kDebugMode;

  @visibleForTesting
  static LogSink sink = _developerSink;

  static const String _name = 'portalcards';

  // Levels follow package:logging (dart:developer convention).
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

  /// Restores the defaults after a test changed them.
  @visibleForTesting
  static void reset() {
    enabled = kDebugMode;
    sink = _developerSink;
  }
}
