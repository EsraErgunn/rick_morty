import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/widgets/portal/portal_spiral_painter.dart';

/// The battle arena, drawn in code: starry indigo space on top, a big green
/// portal turning slowly behind the stage, alien ground with glowing cracks
/// at the bottom. One ticker drives the portal and the star twinkle; with
/// reduced motion everything stands still.
class ArenaBackground extends StatefulWidget {
  const ArenaBackground({required this.child, super.key});

  final Widget child;

  @override
  State<ArenaBackground> createState() => _ArenaBackgroundState();
}

class _ArenaBackgroundState extends State<ArenaBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: AppMotion.arenaSpin,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  /// Background portal brightness: present but well behind the cards.
  static const double _portalIntensity = 0.35;
  static const double _portalVisibility = 0.4;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      RepaintBoundary(child: CustomPaint(painter: _ArenaPainter(_spin))),
      RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, c) {
            final size = c.maxWidth * AppSizes.arenaPortalShare;
            return OverflowBox(
              maxWidth: size,
              maxHeight: size,
              child: SizedBox.square(
                dimension: size,
                child: Opacity(
                  opacity: _portalVisibility,
                  child: AnimatedBuilder(
                    animation: _spin,
                    builder: (context, _) => CustomPaint(
                      painter: PortalSpiralPainter(
                        turn: _spin.value,
                        intensity: _portalIntensity,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      widget.child,
    ],
  );
}

class _ArenaPainter extends CustomPainter {
  _ArenaPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  /// Fixed seed: the same sky and cracks every battle.
  static const int _seed = 7;
  static const int _stars = 90;
  static const int _cracks = 7;
  static const double _horizon = 0.62;
  static const double _twinkles = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(_seed);
    final horizonY = size.height * _horizon;

    // Space.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.arenaSpaceTop, AppColors.arenaSpaceBottom],
        ).createShader(Rect.fromLTWH(0, 0, size.width, horizonY)),
    );

    // Stars (twinkle with the spin ticker).
    final star = Paint()..color = AppColors.paper;
    for (var i = 0; i < _stars; i++) {
      final p = Offset(
        rnd.nextDouble() * size.width,
        rnd.nextDouble() * horizonY,
      );
      final phase = rnd.nextDouble() * math.pi * 2;
      final glow =
          0.35 +
          0.65 *
              (0.5 + 0.5 * math.sin(t.value * _twinkles * math.pi * 2 + phase));
      star.color = AppColors.paper.withValues(alpha: glow);
      canvas.drawCircle(p, AppSizes.arenaStar * (0.5 + rnd.nextDouble()), star);
    }

    // Alien ground.
    final ground = Path()
      ..moveTo(0, horizonY)
      ..quadraticBezierTo(
        size.width / 2,
        horizonY - size.height * 0.05,
        size.width,
        horizonY,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas
      ..drawPath(
        ground,
        Paint()
          ..shader =
              const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.arenaGroundTop, AppColors.arenaGroundBottom],
              ).createShader(
                Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
              ),
      )
      ..drawPath(
        ground,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppOutline.thick
          ..color = AppColors.ink,
      );

    // Glowing cracks: a wide faint stroke under a thin bright one (no blur).
    final pulse = 0.6 + 0.4 * math.sin(t.value * math.pi * 2 * 4);
    final wide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = AppOutline.thick * 2.5
      ..color = AppColors.portal.withValues(alpha: 0.18 * pulse);
    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = AppOutline.thin
      ..color = AppColors.portalHot.withValues(alpha: 0.85 * pulse);
    for (var i = 0; i < _cracks; i++) {
      final crack = Path();
      var p = Offset(
        rnd.nextDouble() * size.width,
        horizonY + rnd.nextDouble() * (size.height - horizonY) * 0.9,
      );
      crack.moveTo(p.dx, p.dy);
      final dir = rnd.nextBool() ? 1 : -1;
      for (var k = 0; k < 5; k++) {
        p += Offset(
          dir * (12 + rnd.nextDouble() * 28),
          (rnd.nextDouble() - 0.4) * 18,
        );
        crack.lineTo(p.dx, p.dy);
      }
      canvas
        ..drawPath(crack, wide)
        ..drawPath(crack, thin);
    }
  }

  @override
  bool shouldRepaint(_ArenaPainter old) => false;
}

/// A glowing platform ring drawn under a team row (behind the cards).
class ArenaPlatform extends StatelessWidget {
  const ArenaPlatform({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: const _PlatformPainter(), child: child);
}

class _PlatformPainter extends CustomPainter {
  const _PlatformPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Rect.fromCenter(
      center: Offset(
        size.width / 2,
        size.height - AppSizes.arenaRingHeight / 3,
      ),
      width: size.width * 1.04,
      height: AppSizes.arenaRingHeight,
    );
    canvas
      ..drawOval(
        ring.inflate(AppOutline.thick * 2),
        Paint()..color = AppColors.portal.withValues(alpha: 0.12),
      )
      ..drawOval(
        ring,
        Paint()..color = AppColors.portal.withValues(alpha: 0.22),
      )
      ..drawOval(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppOutline.thick
          ..color = AppColors.portalHot.withValues(alpha: 0.8),
      );
  }

  @override
  bool shouldRepaint(_PlatformPainter old) => false;
}
