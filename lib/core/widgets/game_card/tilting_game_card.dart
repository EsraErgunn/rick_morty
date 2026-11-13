import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';

import '../../../app/theme/card_style.dart';
import '../../sensors/tilt_stream.dart';

/// Kartı kurar; [tilt] holo katmanı için anlık eğimdir.
typedef TiltedBuilder = Widget Function(
  BuildContext context,
  ValueListenable<Offset> tilt,
);

/// Bir kart için 3D eğim + ışık (sensör kuralları). flutter_tilt'in kendi sensörleri
/// kapalı; bir [TiltController] [TiltStream] ile beslenir ve dokunarak sürükleme
/// yedek olarak açık kalır. İki girdi de `onGestureMove`'a ulaşır (deneme
/// 2026-11-12), bu yüzden [TiltedBuilder]'ın `tilt` değeri 3D eğim ve holo için
/// tek değerdir: flutter_tilt `areaProgress`, (1, 1) = sol üst aşağı eğik.
///
/// Uygulama arka plana geçince sensör duraklar.
/// Tüm flutter_tilt kullanımı bu dosyada kalır (plan riski: API değişiklikleri).
class TiltingGameCard extends StatefulWidget {
  const TiltingGameCard({
    required this.tiltStream,
    required this.builder,
    super.key,
  });

  final TiltStream tiltStream;
  final TiltedBuilder builder;

  @override
  State<TiltingGameCard> createState() => _TiltingGameCardState();
}

class _TiltingGameCardState extends State<TiltingGameCard>
    with WidgetsBindingObserver {
  final TiltController _controller = TiltController();
  final ValueNotifier<Offset> _tilt = ValueNotifier(Offset.zero);
  StreamSubscription<Offset>? _sensor;
  Size _size = Size.zero;

  static const int _fps = 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sensor = widget.tiltStream.stream.listen(_onSensor);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.tiltStream.resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      widget.tiltStream.pause();
    }
  }

  /// Sensör [-1, 1] → kartın içinde bir nokta (merkez = durma).
  void _onSensor(Offset t) {
    if (_size.isEmpty) return;
    final half = _size.center(Offset.zero);
    final p = Offset(half.dx * (1 + t.dx), half.dy * (1 - t.dy));
    _controller.move(
      position: Offset(
        p.dx.clamp(0, _size.width - 1),
        p.dy.clamp(0, _size.height - 1),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_sensor?.cancel());
    unawaited(_controller.dispose());
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _size = constraints.biggest;
      return Tilt.base(
        tiltController: _controller,
        fps: _fps,
        tiltConfig: const TiltConfig(
          angle: CardMetrics.tiltAngle,
          enableGestureSensors: false,
        ),
        lightConfig: const LightConfig(maxIntensity: CardMetrics.tiltLight),
        // flutter_tilt gölgeleri bulanıktır; SPEC §5.4 portal ve holo dışında
        // bulanıklığa izin vermez, bu yüzden sert kart dış çizgisi kalır.
        shadowConfig: const ShadowBaseConfig(disable: true),
        borderRadius: BorderRadius.circular(0),
        clipBehavior: Clip.none,
        onGestureMove: (data, _) => _tilt.value = data.areaProgress,
        onGestureLeave: (data, _) => _tilt.value = data.areaProgress,
        child: widget.builder(context, _tilt),
      );
    },
  );
}
