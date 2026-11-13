import 'package:flutter/material.dart';

import '../../core/game/card_type.dart';
import '../../core/game/rarity.dart';
import 'colors.dart';

/// Nadirlik çerçevesi token'ları (SPEC §5.5).
class RarityStyle {
  const RarityStyle({
    required this.color,
    required this.frameWidth,
    required this.notch,
    this.innerLine = false,
    this.emblem = false,
  });

  final Color color;

  /// Renkli çerçeve bandının kart tasarım birimi cinsinden genişliği.
  final double frameWidth;

  /// Köşe kesiği (0 = yuvarlak köşeler).
  final double notch;

  /// Nadir: çerçevenin içinde 1 birimlik `paper` çizgisi.
  final bool innerLine;

  /// Efsanevi: üst ortada portal halkası amblemi.
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

/// Kart geometrisi. Kart bu tasarım boyutunda yerleştirilir ve sığacak şekilde
/// ölçeklenir (ızgara küçük resmi ya da detay sayfası), böylece yazı boyutları orantılı kalır.
abstract final class CardMetrics {
  static const double designWidth = 250;
  static const double aspect = 5 / 7;
  static const double designHeight = designWidth / aspect;

  /// Gövde yüksekliğinin görsele ayrılan payı (SPEC §5.5: %60).
  static const double artShare = 0.6;

  static const double innerLineWidth = 1;
  static const double emblemSize = 22;
  static const double padding = 8;
  static const double iconSize = 16;

  /// Öne çıkan karakterler: portal yeşili iç çizgi [GM §12.1].
  static const double featuredLine = 2;
  static const double featuredBadge = 20;

  /// Öne çıkan 2.5D görsel: kesilmiş karakter, görsel penceresinin genişliğinden
  /// bu kadar büyük çizilir ve üst kenarının bu kadar üstüne çıkar.
  static const double featuredCutoutScale = 1.1;
  static const double featuredPopOut = 12;

  /// Tam eğimde tasarım birimi cinsinden eğim paralaksı: karakter arka plana
  /// göre hareket eder (arka plan daha derinde, karakter daha yakında).
  static const double featuredParallaxBack = 3;
  static const double featuredParallaxFront = 9;

  /// Arka plan kenarları hiç görünmesin diye bu kadar büyük çizilir.
  static const double featuredBackOverscan = 1.06;

  /// Kesilmiş karakterin arkasındaki arka plan parlaklığı (derinlik ipucu).
  static const double featuredBackBrightness = 0.7;

  /// Karakter karttan çıkmışken görsel penceresinin parlaklığı.
  static const double featuredEmptyArt = 0.35;

  /// Derece cinsinden en fazla 3D eğim (flutter_tilt `TiltConfig.angle`, SPEC §4.5).
  static const double tiltAngle = 6;

  /// Eğim ışık parlamasının en yüksek gücü (0..1).
  static const double tiltLight = 0.2;
}

/// Kart tipi başına Material ikonu (tip asla yalnızca renkle gösterilmez).
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
