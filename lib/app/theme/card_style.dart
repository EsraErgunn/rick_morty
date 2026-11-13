import 'package:flutter/material.dart';

import '../../core/game/card_type.dart';
import '../../core/game/rarity.dart';
import 'colors.dart';

/// Rarity frame tokens (SPEC §5.5).
class RarityStyle {
  const RarityStyle({
    required this.color,
    required this.frameWidth,
    required this.notch,
    this.innerLine = false,
    this.emblem = false,
  });

  final Color color;

  /// Width of the colored frame band in card design units.
  final double frameWidth;

  /// Corner cut (0 = rounded corners).
  final double notch;

  /// Rare: 1 unit `paper` line inside the frame.
  final bool innerLine;

  /// Legendary: portal-ring emblem at top center.
  final bool emblem;

  static RarityStyle of(Rarity rarity) => switch (rarity) {
    Rarity.common => const RarityStyle(
      color: AppColors.rarityCommon,
      frameWidth: 4,
      notch: 0,
    ),
    Rarity.rare => const RarityStyle(
      color: AppColors.rarityRare,
      frameWidth: 5,
      notch: 0,
      innerLine: true,
    ),
    Rarity.epic => const RarityStyle(
      color: AppColors.rarityEpic,
      frameWidth: 6,
      notch: 6,
    ),
    Rarity.legendary => const RarityStyle(
      color: AppColors.rarityLegendary,
      frameWidth: 7,
      notch: 6,
      emblem: true,
    ),
  };
}

/// Card geometry. The card is laid out at this design size and scaled to
/// fit (grid thumbnail or detail page), so text sizes stay proportional.
abstract final class CardMetrics {
  static const double designWidth = 250;
  static const double aspect = 5 / 7;
  static const double designHeight = designWidth / aspect;

  /// Share of the body height used by the art (SPEC §5.5: 60%).
  static const double artShare = 0.6;

  static const double innerLineWidth = 1;
  static const double emblemSize = 22;
  static const double padding = 8;
  static const double iconSize = 16;

  /// Featured characters: portal-green inner line [GM §12.1].
  static const double featuredLine = 2;
  static const double featuredBadge = 20;

  /// Featured 2.5D art: the cut-out character is drawn this much larger
  /// than the art window width and rises this far above its top edge.
  static const double featuredCutoutScale = 1.1;
  static const double featuredPopOut = 12;

  /// Tilt parallax in design units at full tilt: the character moves
  /// against the background (background deeper, character nearer).
  static const double featuredParallaxBack = 3;
  static const double featuredParallaxFront = 9;

  /// The background is drawn this much larger so its edges never show.
  static const double featuredBackOverscan = 1.06;

  /// Background brightness behind the cut-out (depth cue).
  static const double featuredBackBrightness = 0.7;

  /// Art window brightness while the character is out of the card.
  static const double featuredEmptyArt = 0.35;

  /// Max 3D tilt in degrees (flutter_tilt `TiltConfig.angle`, SPEC §4.5).
  static const double tiltAngle = 6;

  /// Max strength of the tilt light sheen (0..1).
  static const double tiltLight = 0.2;
}

/// Material icon per card type (type is never shown by color alone).
abstract final class CardTypeIcons {
  static IconData of(CardType type) => switch (type) {
    CardType.human => Icons.person,
    CardType.robot => Icons.smart_toy,
    CardType.alien => Icons.rocket_launch,
    CardType.beast => Icons.pets,
    CardType.myth => Icons.auto_awesome,
    CardType.neutral => Icons.blur_on,
  };
}
