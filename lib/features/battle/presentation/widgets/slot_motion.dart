import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/game/battle_model.dart';

/// Bir kartın hareketinin tek karesi: kayma, dönüş ve basılma-esneme,
/// artı kartın üstündeki parlama.
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

  /// Kartın üstündeki parlamanın 0..1 opaklığı.
  final double flash;
  final Color flashColor;

  Matrix4 get matrix => Matrix4.identity()
    ..translateByDouble(offset.dx, offset.dy, 0, 1)
    ..rotateZ(angle)
    ..scaleByDouble(scaleX, scaleY, 1, 1);

  static const SlotPose rest = SlotPose();
}

/// Savaş animasyonları için saf poz hesabı (SPEC §4.7). [v] 0..1 arasıdır.
abstract final class SlotPoses {
  static const int _shakeWaves = 4;
  static const int _flickers = 4;

  static double _seg(double v, double from, double to) =>
      ((v - from) / (to - from)).clamp(0.0, 1.0);

  /// Rakibe doğru: oyuncu için yukarı, rakip için aşağı.
  static double _forward(Side side) => side == Side.player ? -1 : 1;

  /// Saldırı: hazırlık (geriye çömelme), dönerek ve esneyerek sıçrama, hedefte
  /// çarpma basıklığı, dönüş.
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
        // Zıplama: uçarken yana doğru bir yay.
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

  /// Vuruş: sarsıntı, saldırandan uzağa geri itilme, kırmızı parlama. [heavy]
  /// (kritik / süper etkili): iki kat sarsıntı ve yanıp sönen ışık.
  static SlotPose hit(double v, Side side, {required bool heavy}) {
    final amp = heavy ? AppSizes.battleCritShake : AppSizes.battleHitShake;
    final fade = 1 - v;
    final back = -_forward(side); // diğer takımdan uzağa itilir
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

  /// Her inişte basılmayla iki zıplama.
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

/// Kart merkezinden parçacık patlaması (vuruş çarpması).
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
