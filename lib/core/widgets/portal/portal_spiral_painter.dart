import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';

/// Shader'sız portal: düz disk, üç sarmal kol, mürekkep halka. `portal.frag`
/// yüklenemezse kullanılır (ve `PortalLoader`'ın yedeğinde).
class PortalSpiralPainter extends CustomPainter {
  const PortalSpiralPainter({
    required this.turn,
    required this.intensity,
    this.color = AppColors.portal,
  });

  /// 0.0 ile 1.0 arası, bir tam dönüş.
  final double turn;

  /// 0.0 (sönük) ile 1.0 (tam) arası.
  final double intensity;
  final Color color;

  static const int _arms = 3;
  static const int _steps = 48;
  static const double _armTurns = 1.25;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - AppOutline.thick;
    final k = intensity.clamp(0.0, 1.0);

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Color.lerp(AppColors.voidRaised, color, k)!,
    );

    final hot = Color.lerp(color, AppColors.paper, 0.55)!;
    final arm = Paint()
      ..color = hot.withValues(alpha: 0.25 + 0.75 * k)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.12;

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(turn * 2 * math.pi);
    for (var a = 0; a < _arms; a++) {
      final start = a * 2 * math.pi / _arms;
      final path = Path()..moveTo(0, 0);
      for (var i = 1; i <= _steps; i++) {
        final t = i / _steps;
        final angle = start + t * _armTurns * 2 * math.pi;
        final r = t * radius * 0.85;
        path.lineTo(r * math.cos(angle), r * math.sin(angle));
      }
      canvas.drawPath(path, arm);
    }
    canvas
      ..restore()
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppOutline.thick * 2,
      );
  }

  @override
  bool shouldRepaint(PortalSpiralPainter old) =>
      old.turn != turn || old.intensity != intensity || old.color != color;
}
