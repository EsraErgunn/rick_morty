import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/game/battle_model.dart';

/// One frame of a card's motion: offset, rotation and squash & stretch,
/// plus the flash over the card.
final class SlotPose {
  const SlotPose({
    this.offset = Offset.zero,
    this.angle = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.flash = 0,
    this.flashColor = AppColors.danger,
  });

  final Offset offset;
  final double angle;
  final double scaleX;
  final double scaleY;

  /// 0..1 opacity of the flash over the card.
  final double flash;
  final Color flashColor;

  Matrix4 get matrix => Matrix4.identity()
    ..translateByDouble(offset.dx, offset.dy, 0, 1)
    ..rotateZ(angle)
    ..scaleByDouble(scaleX, scaleY, 1, 1);

  static const SlotPose rest = SlotPose();
}

/// Pure pose math for the battle animations (SPEC §4.7). [v] is 0..1.
abstract final class SlotPoses {
  static const int _shakeWaves = 4;
  static const int _flickers = 4;

  static double _seg(double v, double from, double to) =>
      ((v - from) / (to - from)).clamp(0.0, 1.0);

  /// Toward the enemy: up for the player, down for the enemy.
  static double _forward(Side side) => side == Side.player ? -1 : 1;

  /// Attack: wind-up (crouch back), leap with spin and stretch, impact
  /// squash on the target, return.
  static SlotPose lunge(double v, Side side) {
    final dir = _forward(side);
    const squash = AppSizes.battleSquash;
    if (v < 0.22) {
      final e = Curves.easeOut.transform(_seg(v, 0, 0.22));
      return SlotPose(
        offset: Offset(0, -dir * AppSizes.battleWindUp * e),
        angle: -dir * AppSizes.battleLungeSpin * 0.4 * e,
        scaleX: 1 + squash * 0.5 * e,
        scaleY: 1 - squash * 0.5 * e,
      );
    }
    if (v < 0.57) {
      final e = Curves.easeIn.transform(_seg(v, 0.22, 0.57));
      final arc = math.sin(math.pi * e);
      final y =
          -dir * AppSizes.battleWindUp +
          dir * (AppSizes.battleWindUp + AppSizes.battleDash) * e;
      return SlotPose(
        // The hop: a sideways arc while it flies.
        offset: Offset(
          dir * AppSizes.battleHop * 0.5 * arc,
          y - AppSizes.battleHop * 0.3 * arc,
        ),
        angle: dir * AppSizes.battleLungeSpin * arc,
        scaleX: 1 - squash * 0.6 * arc + 0.1 * arc,
        scaleY: 1 + squash * arc + 0.1 * arc,
      );
    }
    if (v < 0.7) {
      final s = math.sin(math.pi * _seg(v, 0.57, 0.7));
      return SlotPose(
        offset: Offset(0, dir * AppSizes.battleDash),
        scaleX: 1 + squash * s,
        scaleY: 1 - squash * s,
      );
    }
    final e = AppMotion.move.transform(_seg(v, 0.7, 1));
    return SlotPose(offset: Offset(0, dir * AppSizes.battleDash * (1 - e)));
  }

  /// Hit: shake, knock-back away from the attacker, red flash. [heavy]
  /// (crit / super effective): twice the shake and a flashing light.
  static SlotPose hit(double v, Side side, {required bool heavy}) {
    final amp = heavy ? AppSizes.battleCritShake : AppSizes.battleHitShake;
    final fade = 1 - v;
    final back = -_forward(side); // pushed away from the other team
    final knock = math.sin(math.pi * math.min(1, v * 2)) * fade;
    final flicker = heavy && (v * _flickers * 2).floor().isEven;
    return SlotPose(
      offset: Offset(
        amp * math.sin(v * math.pi * 2 * _shakeWaves) * fade,
        back * AppSizes.battleWindUp * knock,
      ),
      angle: back * AppSizes.battleKnockTilt * knock,
      scaleX: 1 - AppSizes.battleSquash * 0.4 * knock,
      scaleY: 1 - AppSizes.battleSquash * 0.4 * knock,
      flash: (heavy ? 0.75 : 0.55) * fade,
      flashColor: flicker ? AppColors.portalHot : AppColors.danger,
    );
  }

  static SlotPose dodge(double v) =>
      SlotPose(offset: Offset(AppSizes.battleLunge * math.sin(math.pi * v), 0));

  /// Two hops with a squash on each landing.
  static SlotPose victory(double v) {
    final hop = (math.sin(math.pi * 2 * v)).abs();
    final landing = 1 - hop;
    return SlotPose(
      offset: Offset(0, -AppSizes.battleVictoryHop * hop * (1 - 0.3 * v)),
      scaleX: 1 + AppSizes.battleSquash * 0.5 * landing,
      scaleY: 1 - AppSizes.battleSquash * 0.5 * landing,
    );
  }
}

/// Particle burst out of the card center (hit impact).
class BurstPainter extends CustomPainter {
  const BurstPainter({required this.v, required this.heavy});

  final double v;
  final bool heavy;

  static const int _count = 12;

  @override
  void paint(Canvas canvas, Size size) {
    if (v <= 0 || v >= 1) return;
    final center = size.center(Offset.zero);
    final e = Curves.easeOut.transform(v);
    final spread = AppSizes.battleParticleSpread * (heavy ? 1.4 : 1);
    final n = heavy ? _count + 6 : _count;
    for (var i = 0; i < n; i++) {
      final a = i * math.pi * 2 / n + (i.isEven ? 0.2 : -0.1);
      final reach = spread * e * (i.isEven ? 1 : 0.7);
      final p = center + Offset(math.cos(a), math.sin(a)) * reach;
      final r = AppSizes.battleParticle * (1 - v);
      canvas
        ..drawCircle(p, r + 1.5, Paint()..color = AppColors.ink)
        ..drawCircle(
          p,
          r,
          Paint()
            ..color = i % 3 == 0
                ? AppColors.paper
                : heavy
                ? AppColors.rarityLegendary
                : AppColors.portalHot,
        );
    }
  }

  @override
  bool shouldRepaint(BurstPainter old) => old.v != v || old.heavy != heavy;
}
