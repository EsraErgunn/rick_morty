import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/motion.dart';
import '../shader_cache.dart';
import 'portal_spiral_painter.dart';

/// Portal yoğunluk seviyeleri (SPEC §2.3 AC5).
abstract final class PortalIntensity {
  static const double idle = 0.15;
  static const double open = 1.0;

  /// Splash hata durumu (SPEC §4.1).
  static const double dim = 0.05;
}

/// Canlı portal: bir ticker ile sürülen `portal.frag` ya da shader yoksa sarmal
/// çizici. `RepaintBoundary` içinde yalnızca kendini yeniden çizer (kare başına
/// yeniden kurulum yok).
///
/// [intensity] ve [legendary] çağıran tarafından canlandırılır (portal bloc'u,
/// splash); kırmızıya renk geçişi burada `AppMotion.slow` süresince yumuşatılır.
/// Azaltılmış harekette girdap yavaş döner.
class PortalView extends StatefulWidget {
  const PortalView({
    required this.shaders,
    this.intensity = PortalIntensity.idle,
    this.legendary = false,
    super.key,
  });

  final ShaderCache shaders;
  final double intensity;
  final bool legendary;

  @override
  State<PortalView> createState() => _PortalViewState();
}

class _PortalViewState extends State<PortalView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final ValueNotifier<double> _time = ValueNotifier(0);
  ui.FragmentShader? _shader;

  /// Azaltılmış harekette gerçek saniye başına girdap zamanı saniyesi.
  static const double _reducedSpeed = 0.2;

  /// Shader'da kayan nokta hassasiyetini korur (zaman başa sarar).
  static const double _wrap = 1000;

  @override
  void initState() {
    super.initState();
    _shader = widget.shaders.portal?.fragmentShader();
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    _time.value = (seconds * (reduce ? _reducedSpeed : 1)) % _wrap;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.legendary ? AppColors.danger : AppColors.portal;
    return RepaintBoundary(
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: target),
        duration: AppMotion.slow,
        builder: (context, color, _) => CustomPaint(
          key: ValueKey(_shader == null ? 'portal-fallback' : 'portal-shader'),
          size: Size.infinite,
          painter: _PortalPainter(
            shader: _shader,
            time: _time,
            intensity: widget.intensity,
            color: color ?? target,
          ),
        ),
      ),
    );
  }
}

class _PortalPainter extends CustomPainter {
  _PortalPainter({
    required this.shader,
    required this.time,
    required this.intensity,
    required this.color,
  }) : super(repaint: time);

  final ui.FragmentShader? shader;
  final ValueListenable<double> time;
  final double intensity;
  final Color color;

  /// Yedek sarmal: girdap zamanının bu kadar saniyesinde bir tur.
  static const double _fallbackTurnSeconds = 3.2;

  @override
  void paint(Canvas canvas, Size size) {
    final s = shader;
    if (s == null) {
      PortalSpiralPainter(
        turn: (time.value / _fallbackTurnSeconds) % 1,
        intensity: intensity.clamp(0.35, 1.0),
        color: color,
      ).paint(canvas, size);
      return;
    }
    s
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time.value)
      ..setFloat(3, intensity)
      ..setFloat(4, color.r)
      ..setFloat(5, color.g)
      ..setFloat(6, color.b);
    canvas.drawRect(Offset.zero & size, Paint()..shader = s);
  }

  @override
  bool shouldRepaint(_PortalPainter old) =>
      old.shader != shader || old.intensity != intensity || old.color != color;
}
