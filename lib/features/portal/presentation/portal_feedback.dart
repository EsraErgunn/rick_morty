import 'dart:async';

import '../../../core/audio/audio_assets.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/game/rarity.dart';
import '../../../core/haptics/haptics_service.dart';

/// Sound + haptic for every portal moment (SPEC §4.3), in one place so the
/// page and the reveal scene only say *what* happened.
class PortalFeedback {
  const PortalFeedback({required this.audio, required this.haptics});

  final AudioService audio;
  final HapticsService haptics;

  void notEnoughCoins() => unawaited(haptics.play(HapticMoment.notEnoughCoins));

  void charge() {
    unawaited(audio.play(Sfx.portalCharge));
    unawaited(haptics.play(HapticMoment.portalCharge));
  }

  void burst({required bool legendary}) {
    unawaited(audio.play(Sfx.portalOpen));
    unawaited(haptics.play(HapticMoment.portalOpen));
    if (legendary) unawaited(audio.playSting());
  }

  void land() {
    unawaited(audio.play(Sfx.hit));
    unawaited(haptics.play(HapticMoment.cardLand));
  }

  void flip(Rarity rarity) {
    unawaited(audio.play(Sfx.cardFlip));
    unawaited(haptics.play(HapticMoment.cardFlip));
    switch (rarity) {
      case Rarity.common:
        break;
      case Rarity.rare || Rarity.epic:
        unawaited(audio.play(Sfx.rareReveal));
        unawaited(haptics.play(HapticMoment.rareReveal));
      case Rarity.legendary:
        unawaited(audio.play(Sfx.legendaryReveal));
        unawaited(haptics.play(HapticMoment.legendaryReveal));
    }
  }

  /// Featured image settles into its card [GM §12.3].
  void featureSettle() => unawaited(haptics.play(HapticMoment.cardLand));

  void duplicateCoins() {
    unawaited(audio.play(Sfx.coin));
    unawaited(haptics.play(HapticMoment.coin));
  }

  void button() {
    unawaited(audio.play(Sfx.buttonTap));
    unawaited(haptics.play(HapticMoment.buttonTap));
  }
}
