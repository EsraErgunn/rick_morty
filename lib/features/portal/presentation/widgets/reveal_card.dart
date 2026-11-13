import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../core/widgets/game_card/card_back.dart';
import 'reveal_effects.dart';
import 'reveal_timeline.dart';

/// [t] zaman çizelgesi noktasında kartın nerede olduğu ve nasıl deforme olduğu
/// (SPEC §4.3): çıkış (büyük bir aşmayla ölçek 0.1 → 1, 2.5 Y dönüşü
/// artı bir düzlem içi dönüş), yerçekimiyle düşüş, basılma.
class RevealCardPose {
  const RevealCardPose({
    required this.center,
    required this.scale,
    required this.turn,
    required this.squash,
    required this.visible,
    required this.shadow,
    this.spin = 0,
  });

  factory RevealCardPose.at(
    RevealTimeline timeline,
    double t, {
    required Offset from,
    required Offset to,
  }) {
    final e = AppMotion.emerge.transform(timeline.emerge.progress(t));
    final f = AppMotion.fall.transform(timeline.fall.progress(t));
    final l = timeline.land.progress(t);
    return RevealCardPose(
      center: Offset.lerp(from, to, f)!,
      scale:
          _minScale + (1 - _minScale) * e + _overshoot * math.sin(math.pi * e),
      turn: _turns * 2 * math.pi * (1 - e),
      spin: 2 * math.pi * (1 - e),
      squash: RevealTimeline.squash(l),
      visible: t >= timeline.emerge.start,
      shadow: t < timeline.fall.start ? 0 : (f * 0.8 + (l > 0 ? 0.2 : 0)),
    );
  }

  static const double _minScale = 0.1;
  static const double _turns = 2.5;

  /// Çıkışın yarısında ek boyut: kart büyük bir şekilde fırlar.
  static const double _overshoot = 0.45;

  /// Radyan cinsinden düzlem içi dönüş (bir tur, 0'a geri çözülerek).
  final double spin;

  final Offset center;
  final double scale;

  /// Radyan cinsinden Y dönüşü (izleyiciye bakarken 0).
  final double turn;
  final (double, double) squash;
  final bool visible;

  /// Zemin gölgesinin 0..1 gücü.
  final double shadow;

  /// Kart kutusu için dönüşüm (çıkış dönüşü + ölçek, altta basılma).
  Matrix4 transform(Size card) {
    final (sx, sy) = squash;
    final bottomShift = card.height / 2 * (1 - sy);
    return Matrix4.identity()
      ..translateByDouble(0, bottomShift, 0, 1)
      ..scaleByDouble(sx * scale, sy * scale, 1, 1)
      ..setEntry(3, 2, AppMotion.perspective)
      ..rotateZ(spin)
      ..rotateY(turn);
  }
}

/// Giriş sırasında kartın arka yüzü: efsanevi için siyah siluet
/// (SPEC §4.3), çevrilmeden önce altın süpürme ile.
class RevealBack extends StatelessWidget {
  const RevealBack({required this.silhouette, required this.sweep, super.key});

  final bool silhouette;

  /// 0..1 altın süpürme ilerlemesi (efsanevi, çevirmeden önce).
  final double sweep;

  @override
  Widget build(BuildContext context) {
    final back = silhouette
        ? const ColorFiltered(
            colorFilter: ColorFilter.mode(AppColors.ink, BlendMode.srcATop),
            child: CardBack(),
          )
        : const CardBack();
    if (sweep <= 0) return back;
    return Stack(
      children: [
        back,
        Positioned.fill(
          child: CustomPaint(painter: GoldSweepPainter(progress: sweep)),
        ),
      ],
    );
  }
}
