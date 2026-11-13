import 'dart:async';

import '../../../core/audio/audio_assets.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/game/battle_model.dart';
import '../../../core/game/card_type.dart';
import '../../../core/game/featured.dart';
import '../../../core/haptics/haptics_service.dart';

/// Her savaş anı için ses + titreşim (SPEC §4.7); tekrar oynatılan olaylarla
/// sürülür, böylece sayfa yalnızca *ne* olduğunu söyler.
class BattleFeedback {
  const BattleFeedback({required this.audio, required this.haptics});

  final AudioService audio;
  final HapticsService haptics;

  void _do(Sfx sfx, HapticMoment moment) {
    unawaited(audio.play(sfx));
    unawaited(haptics.play(moment));
  }

  /// Arena müziği: `battle_loop`, döngülü, savaş öncesi ekrandan sonuca
  /// kadar (zaten çalıyorsa hiçbir şey yapmaz; müzik anahtarına uyar).
  void enter() => unawaited(audio.playMusic(Music.battleLoop));

  /// Sonuç ekranı: müzik durur (zafer/yenilgi sesi tek başına çalar).
  void resultShown() => unawaited(audio.stopMusic());

  /// Menüye dönüş: `menu_loop`.
  void leave() => unawaited(audio.playMusic(Music.menuLoop));

  /// Saldıran / hedef seçimi.
  void select() => _do(Sfx.buttonTap, HapticMoment.buttonTap);

  void event(BattleEvent event) {
    switch (event) {
      case Dodged():
        _do(Sfx.cardFlip, HapticMoment.cardFlip);
      case Damaged(:final isCrit, :final effectiveness, :final signature):
        if (isCrit && signature == Signature.genius) {
          _do(Sfx.geniusCrit, HapticMoment.crit);
        } else if (isCrit) {
          _do(Sfx.critHit, HapticMoment.crit);
        } else if (effectiveness == Effectiveness.superEffective) {
          _do(Sfx.superEffective, HapticMoment.superEffective);
        } else if (effectiveness == Effectiveness.notVeryEffective) {
          _do(Sfx.hit, HapticMoment.cardFlip);
        } else {
          _do(Sfx.hit, HapticMoment.hit);
        }
        if (isCrit && effectiveness == Effectiveness.superEffective) {
          unawaited(audio.play(Sfx.superEffective));
        }
      case Fainted():
        _do(Sfx.faint, HapticMoment.hit);
      case Revived():
        _do(Sfx.rareReveal, HapticMoment.rareReveal);
      case SignatureTriggered(:final signature):
        if (signature == Signature.missionComplete) {
          _do(Sfx.meeseeksPoof, HapticMoment.cardFlip);
        } else if (signature != Signature.genius) {
          _do(Sfx.superEffective, HapticMoment.hit);
        }
      case BattleEnded(:final result):
        switch (result) {
          case BattleResult.victory:
            _do(Sfx.victory, HapticMoment.crit);
          case BattleResult.defeat:
            _do(Sfx.defeat, HapticMoment.hit);
          case BattleResult.draw:
            _do(Sfx.defeat, HapticMoment.cardFlip);
        }
      case TurnStarted() || Attacked() || Healed() || TurnEnded():
        break;
    }
  }

  /// Coin sayımının bir adımı.
  void coinTick() => _do(Sfx.coin, HapticMoment.coin);
}
