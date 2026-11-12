import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

/// Ring burst + flash out of the portal center (burst phase).
class BurstPainter extends CustomPainter {
  const BurstPainter({
    required this.progress,
    required this.color,
    this.center,
  });

  /// 0 → 1 over the burst (and a little after).
  final double progress;
  final Color color;

  /// Ring center (the portal); defaults to the middle of the canvas.
  final Offset? center;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = this.center ?? size.center(Offset.zero);
    final maxR = size.longestSide * 0.6;
    final fade = 1 - progress;
    canvas
      ..drawCircle(
        center,
        maxR * progress,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18 * fade
          ..color = Color.lerp(
            color,
            AppColors.paper,
            0.5,
          )!.withValues(alpha: fade),
      )
      ..drawRect(
        Offset.zero & size,
        Paint()..color = AppColors.portalHot.withValues(alpha: 0.35 * fade),
      );
  }

  @override
  bool shouldRepaint(BurstPainter old) =>
      old.progress != progress || old.color != color || old.center != center;
}

/// Soft ink shadow under the falling card. The only blurred shadow outside
/// the shaders, allowed for the portal scene (SPEC §4.3).
class CardShadowPainter extends CustomPainter {
  const CardShadowPainter({required this.strength});

  /// 0 (card far) → 1 (card on the floor).
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final w = size.width * (0.35 + 0.65 * strength);
    canvas.drawOval(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: w,
        height: size.height * strength,
      ),
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.65 * strength)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(CardShadowPainter old) => old.strength != strength;
}

/// Rarity-color rays behind the card when it flips (rare and up).
class RarityRaysPainter extends CustomPainter {
  const RarityRaysPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const int _rays = 14;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    final r = size.shortestSide * (0.3 + 0.7 * progress);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55 * (1 - progress));
    for (var i = 0; i < _rays; i++) {
      final a = i * 2 * math.pi / _rays + progress * 0.6;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + r * math.cos(a - 0.08),
          center.dy + r * math.sin(a - 0.08),
        )
        ..lineTo(
          center.dx + r * math.cos(a + 0.08),
          center.dy + r * math.sin(a + 0.08),
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(RarityRaysPainter old) =>
      old.progress != progress || old.color != color;
}

/// Gold light sweep over the legendary card back before the flip.
class GoldSweepPainter extends CustomPainter {
  const GoldSweepPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final x = -size.width + 3 * size.width * progress;
    final rect = Rect.fromLTWH(x, 0, size.width, size.height);
    const gold = AppColors.rarityLegendary;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          colors: [gold.withValues(alpha: 0), gold, gold.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(GoldSweepPainter old) => old.progress != progress;
}
