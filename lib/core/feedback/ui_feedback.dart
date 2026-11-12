import 'dart:async';

import '../audio/audio_assets.dart';
import '../audio/audio_service.dart';
import '../haptics/haptics_service.dart';

/// Shared sound + haptic for plain UI moments (SPEC §4.2, §4.9), so every
/// screen sounds and feels the same. Screen-specific moments (portal,
/// battle) have their own feedback classes.
class UiFeedback {
  const UiFeedback({required this.audio, required this.haptics});

  final AudioService audio;
  final HapticsService haptics;

  /// Any button or list entry.
  void tap() {
    unawaited(audio.play(Sfx.buttonTap));
    unawaited(haptics.play(HapticMoment.buttonTap));
  }

  /// A switch in Settings.
  void toggle() {
    unawaited(audio.play(Sfx.buttonTap));
    unawaited(haptics.play(HapticMoment.toggle));
  }

  /// The coin counter changed.
  void coins() {
    unawaited(audio.play(Sfx.coin));
    unawaited(haptics.play(HapticMoment.coin));
  }

  /// A card turned over.
  void cardFlip() {
    unawaited(audio.play(Sfx.cardFlip));
    unawaited(haptics.play(HapticMoment.cardFlip));
  }
}
