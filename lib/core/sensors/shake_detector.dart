import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

import 'sensor_support.dart';
import 'tilt_stream.dart' show Gravity;

/// Doğrusal ivme kaynağı (yerçekimi çıkarılmış), m/s².
typedef MotionSource = Stream<Gravity> Function();

/// Monoton saat, testler için enjekte edilir.
typedef Clock = Duration Function();

Stream<Gravity> _deviceMotion() => deviceHasMotionSensors
    ? userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
          .map((e) => (x: e.x, y: e.y, z: e.z))
    : const Stream.empty();

final Stopwatch _stopwatch = Stopwatch()..start();
Duration _monotonic() => _stopwatch.elapsed;

/// Portalı açmak için sallama (sensör kuralları): büyüklük ≈ 15 m/s², 500 ms
/// içinde iki tepe, sonra 1,5 sn bekleme. Sensör yalnızca biri dinlerken
/// ve dedektör duraklatılmamışken açıktır.
class ShakeDetector {
  ShakeDetector({this._source = _deviceMotion, this._clock = _monotonic}) {
    _out = StreamController<void>.broadcast(onListen: _open, onCancel: _close);
  }

  static const double threshold = 15;
  static const Duration peakWindow = Duration(milliseconds: 500);
  static const Duration cooldown = Duration(milliseconds: 1500);

  final MotionSource _source;
  final Clock _clock;
  late final StreamController<void> _out;
  StreamSubscription<Gravity>? _sub;
  bool _paused = false;

  bool _above = false;
  Duration? _firstPeak;
  Duration? _lastShake;

  /// Algılanan her sallama için bir olay.
  Stream<void> get shakes => _out.stream;

  int get activeSubscriptions => _sub == null ? 0 : 1;

  void pause() {
    _paused = true;
    _close();
  }

  void resume() {
    _paused = false;
    if (_out.hasListener) _open();
  }

  void _open() {
    if (_paused || _sub != null) return;
    _above = false;
    _firstPeak = null;
    _sub = _source().listen(_onReading);
  }

  void _close() {
    unawaited(_sub?.cancel());
    _sub = null;
  }

  void _onReading(Gravity a) {
    final magnitude = sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
    final above = magnitude >= threshold;
    final rising = above && !_above;
    _above = above;
    if (!rising) return;

    final now = _clock();
    final last = _lastShake;
    if (last != null && now - last < cooldown) return;

    final first = _firstPeak;
    if (first != null && now - first <= peakWindow) {
      _firstPeak = null;
      _lastShake = now;
      _out.add(null);
    } else {
      _firstPeak = now;
    }
  }

  Future<void> dispose() async {
    _close();
    await _out.close();
  }
}
