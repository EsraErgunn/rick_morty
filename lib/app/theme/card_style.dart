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
