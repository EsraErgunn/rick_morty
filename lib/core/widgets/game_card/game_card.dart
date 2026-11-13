import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../app/theme/card_style.dart';
import '../../../app/theme/spacing.dart';
import '../../cards/game_card_data.dart';
import 'card_front.dart';
import 'rarity_frame_painter.dart';

/// A 5:7 card. Laid out at [CardMetrics] design size and scaled to the
/// space it gets, so it looks the same in a grid and on the detail page.
class GameCard extends StatelessWidget {
  const GameCard({
    required this.data,
    this.holo,
    this.hideArt = false,
    this.tilt,
    this.characterOut = false,
    super.key,
  });

  /// Card tilt for the 2.5D parallax (see [CardFront.tilt]).
  final ValueListenable<Offset>? tilt;

  /// The 2.5D character has left the card (see [CardFront.characterOut]).
  final bool characterOut;

  final GameCardData data;

  /// Empty art window (featured entrance).
  final bool hideArt;

  /// Optional foil drawn over the face, clipped to the card shape
  /// (a `HoloLayer`).
  final Widget? holo;

  @override
  Widget build(BuildContext context) {
    final overlay = holo;
    return CardSizer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CardFront(
              data: data,
              hideArt: hideArt,
              tilt: tilt,
              characterOut: characterOut,
            ),
          ),
          if (overlay != null)
            Positioned.fill(
              child: ClipPath(
                clipper: _CardClipper(RarityStyle.of(data.rarity).notch),
                child: overlay,
              ),
            ),
        ],
      ),
    );
  }
}

class _CardClipper extends CustomClipper<Path> {
  const _CardClipper(this.notch);

  final double notch;

  @override
  Path getClip(Size size) => cardShape(
    (Offset.zero & size).deflate(AppOutline.thick / 2),
    notch: notch,
  );

  @override
  bool shouldReclip(_CardClipper old) => old.notch != notch;
}

/// Scales a design-size card face to the available space (5:7).
class CardSizer extends StatelessWidget {
  const CardSizer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: CardMetrics.aspect,
    child: FittedBox(
      child: SizedBox(
        width: CardMetrics.designWidth,
        height: CardMetrics.designHeight,
        child: child,
      ),
    ),
  );
}
