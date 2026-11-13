import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/motion.dart';
import '../../../../core/widgets/portal/portal_spiral_painter.dart';

/// Bayılan kart (SPEC §4.7): döner, küçülür ve arkasında açılıp yeniden kapanan
/// küçük bir portala çekilir; slotta soluk gri bir hayalet kalır.
/// Zombi kart dirilince tersine işler. Azaltılmış hareket: yalnızca kısa bir
/// solma.
class Fainting extends StatelessWidget {
  const Fainting({
    required this.fainted,
    required this.speed,
    required this.child,
    super.key,
  });

  final bool fainted;
  final double speed;
  final Widget child;

  static const double _ghostOpacity = 0.18;
  static const double _ghostScale = 0.22;
  static const double _spins = 1.5;
  static const double _portalShare = 0.9;

  static List<double> _saturation(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return [
      r * i + s, g * i, b * i, 0, 0, //
      r * i, g * i + s, b * i, 0, 0, //
      r * i, g * i, b * i + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fainted ? 1 : 0),
      duration: reduced
          ? AppMotion.battleReduced
          : AppMotion.battleFaint * speed,
      curve: AppMotion.move,
      builder: (context, f, child) {
        final grey = ColorFiltered(
          colorFilter: ColorFilter.matrix(_saturation(1 - f)),
          child: child,
        );
        if (reduced) {
          return Opacity(opacity: 1 - (1 - _ghostOpacity) * f, child: grey);
        }
        // Portal yarı yolda en geniş, sonunda kaybolmuş olur.
        final portal = math.sin(math.pi * f);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (portal > 0)
              Positioned.fill(
                child: FractionallySizedBox(
                  widthFactor: _portalShare * portal,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: PortalSpiralPainter(turn: f * 2, intensity: 1),
                    ),
                  ),
                ),
              ),
            Opacity(
              opacity: 1 - (1 - _ghostOpacity) * f,
              child: Transform.rotate(
                angle: math.pi * 2 * _spins * f,
                child: Transform.scale(
                  scale: 1 - (1 - _ghostScale) * f,
                  child: grey,
                ),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}
