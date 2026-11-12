import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../core/widgets/game_card/card_back.dart';
import 'reveal_effects.dart';
import 'reveal_timeline.dart';

/// Where the card is and how it is deformed at timeline point [t]
/// (SPEC §4.3): emerge (scale 0.1 → 1, 1.5 turns), gravity fall, squash.
class RevealCardPose {
  const RevealCardPose({
    required this.center,
    required this.scale,
    required this.turn,
    required this.squash,
    required this.visible,
    required this.shadow,
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
      scale: _minScale + (1 - _minScale) * e,
      turn: _turns * 2 * math.pi * (1 - e),
      squash: RevealTimeline.squash(l),
      visible: t >= timeline.emerge.start,
      shadow: t < timeline.fall.start ? 0 : (f * 0.8 + (l > 0 ? 0.2 : 0)),
    );
  }

  static const double _minScale = 0.1;
  static const double _turns = 1.5;

  final Offset center;
  final double scale;

  /// Y rotation in radians (0 when facing the viewer).
  final double turn;
  final (double, double) squash;
  final bool visible;

  /// 0..1 strength of the floor shadow.
  final double shadow;

  /// Transform for the card box (emerge spin + scale, squash at the bottom).
  Matrix4 transform(Size card) {
    final (sx, sy) = squash;
    final bottomShift = card.height / 2 * (1 - sy);
    return Matrix4.identity()
      ..translateByDouble(0, bottomShift, 0, 1)
      ..scaleByDouble(sx * scale, sy * scale, 1, 1)
      ..setEntry(3, 2, AppMotion.perspective)
      ..rotateY(turn);
  }
}

/// The card back during the intro: black silhouette for a legendary
/// (SPEC §4.3), with the gold sweep before its flip.
class RevealBack extends StatelessWidget {
  const RevealBack({required this.silhouette, required this.sweep, super.key});

  final bool silhouette;

  /// 0..1 gold sweep progress (legendary, before the flip).
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
