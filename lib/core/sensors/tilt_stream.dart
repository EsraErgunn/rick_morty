import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'sensor_support.dart';

/// m/s² cinsinden tek bir ivmeölçer okuması (yerçekimi dahil).
typedef Gravity = ({double x, double y, double z});

/// Ham bir ivmeölçer akışı açar. Testler sensöre ihtiyaç duymasın diye enjekte edilir.
typedef GravitySource = Stream<Gravity> Function();

Stream<Gravity> _deviceGravity() => deviceHasMotionSensors
    ? accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
          .map((e) => (x: e.x, y: e.y, z: e.z))
    : const Stream.empty();

/// Kartın 3D eğimi ve holo için cihaz eğimi (sensör kuralları): uygulamadaki
/// **tek** eğim sensörü aboneliği.
///
/// ivmeölçer → başladığı andaki duruşa göre → alçak geçiren filtre
/// (α 0.15) → [-1, 1] aralığına sınırla. `dx` > 0: sağ kenar aşağıda; `dy` > 0: üst
/// kenar kullanıcıdan uzakta. Sensör yalnızca biri dinlerken ve akış
/// [pause] ile duraklatılmamışken açıktır.
class TiltStream {
  TiltStream({this._source = _deviceGravity}) {
    _out = StreamController<Offset>.broadcast(
      onListen: _open,
      onCancel: _close,
    );
  }

  static const double alpha = 0.15;
  static const double gravity = 9.81;

  /// Tam sapma ±1'e karşılık gelen eğim (g cinsinden) (yaklaşık ±20°).
  static const double fullTiltG = 0.35;

  final GravitySource _source;
  late final StreamController<Offset> _out;
  StreamSubscription<Gravity>? _sub;
  bool _paused = false;
  Offset? _baseline;
  Offset _filtered = Offset.zero;

  /// Şu an açık sensör abonelikleri (0 veya 1). Testler ve
  /// "tam olarak tek abonelik" kontrolü için.
  int get activeSubscriptions => _sub == null ? 0 : 1;

  /// Gönderilen son değer, dururken (0, 0).
  Offset get current => _filtered;

  Stream<Offset> get stream => _out.stream;

  /// Uygulama arka planda ya da ekran gizli: sensörü kapat (pil).
  void pause() {
    _paused = true;
    _close();
  }

  /// Ekrana geri dönüldü: yeniden aç ve mevcut duruşu durma konumu olarak al.
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
    // Yalpa x'ten (sağ kenar aşağı pozitif olsun diye işaret ters çevrildi), yunuslama y'den.
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
