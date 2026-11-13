import 'dart:async';

import '../audio/audio_assets.dart';
import '../audio/audio_service.dart';
import '../haptics/haptics_service.dart';

/// Sıradan arayüz anları için ortak ses + titreşim (SPEC §4.2, §4.9), böylece her
/// ekran aynı ses ve hissi verir. Ekrana özel anların (portal,
/// savaş) kendi geri bildirim sınıfları vardır.
class UiFeedback {
  const UiFeedback({required this.audio, required this.haptics});

  final AudioService audio;
  final HapticsService haptics;

  /// Herhangi bir buton veya liste öğesi.
  void tap() {
    unawaited(audio.play(Sfx.buttonTap));
    unawaited(haptics.play(HapticMoment.buttonTap));
  }

  /// Ayarlar'daki bir anahtar.
  void toggle() {
    unawaited(audio.play(Sfx.buttonTap));
    unawaited(haptics.play(HapticMoment.toggle));
  }

  /// Coin sayacı değişti.
  void coins() {
    unawaited(audio.play(Sfx.coin));
    unawaited(haptics.play(HapticMoment.coin));
  }

  /// Bir kart çevrildi.
  void cardFlip() {
    unawaited(audio.play(Sfx.cardFlip));
    unawaited(haptics.play(HapticMoment.cardFlip));
  }

  /// Bir şey tamamlandı (deste doldu): `rare_reveal` + orta titreşim.
  void success() {
    unawaited(audio.play(Sfx.rareReveal));
    unawaited(haptics.play(HapticMoment.rareReveal));
  }
}
