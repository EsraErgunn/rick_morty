import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// One accelerometer reading in m/s² (gravity included).
typedef Gravity = ({double x, double y, double z});

/// Opens a raw accelerometer stream. Injected so tests need no sensor.
typedef GravitySource = Stream<Gravity> Function();

Stream<Gravity> _deviceGravity() =>
    accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
        .map((e) => (x: e.x, y: e.y, z: e.z));

/// Device tilt for the card 3D tilt and the holo (sensors rules): the
/// **only** tilt sensor subscription in the app.
///
/// accelerometer → relative to the pose when it started → low-pass
/// (α 0.15) → clamp to [-1, 1]. `dx` > 0: right edge down; `dy` > 0: top
/// edge away from the user. The sensor is open only while someone listens
/// and the stream is not [pause]d.
class TiltStream {
  TiltStream({this._source = _deviceGravity}) {
    _out = StreamController<Offset>.broadcast(
      onListen: _open,
      onCancel: _close,
    );
  }

  static const double alpha = 0.15;
  static const double gravity = 9.81;

  /// Tilt (in g) that maps to full deflection ±1 (about ±20°).
  static const double fullTiltG = 0.35;

  final GravitySource _source;
  late final StreamController<Offset> _out;
  StreamSubscription<Gravity>? _sub;
  bool _paused = false;
  Offset? _baseline;
  Offset _filtered = Offset.zero;

  /// Open sensor subscriptions right now (0 or 1). For tests and the
  /// "exactly one subscription" check.
  int get activeSubscriptions => _sub == null ? 0 : 1;

  /// Last value sent, (0, 0) at rest.
  Offset get current => _filtered;

  Stream<Offset> get stream => _out.stream;

  /// App in background or screen hidden: close the sensor (battery).
  void pause() {
    _paused = true;
    _close();
  }

  /// Back on screen: reopen and take the current pose as rest.
  void resume() {
    _paused = false;
    if (_out.hasListener) _open();
  }

  void _open() {
    if (_paused || _sub != null) return;
    _baseline = null;
    _filtered = Offset.zero;
    _sub = _source().listen(_onReading);
  }

  void _close() {
    unawaited(_sub?.cancel());
    _sub = null;
  }

  void _onReading(Gravity g) {
    // Roll from x (sign flipped so right edge down is positive), pitch from y.
    final raw = Offset(-g.x / gravity, -g.y / gravity);
    final rest = _baseline ??= raw;
    final target = (raw - rest) / fullTiltG;
    _filtered = Offset(
      _clamp(_filtered.dx + alpha * (target.dx - _filtered.dx)),
      _clamp(_filtered.dy + alpha * (target.dy - _filtered.dy)),
    );
    _out.add(_filtered);
  }

  static double _clamp(double v) => v.clamp(-1.0, 1.0);

  Future<void> dispose() async {
    _close();
    await _out.close();
  }
}
