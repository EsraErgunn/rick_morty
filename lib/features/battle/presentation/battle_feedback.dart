import 'dart:async';

import '../../../core/audio/audio_assets.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/game/battle_model.dart';
import '../../../core/game/card_type.dart';
import '../../../core/game/featured.dart';
import '../../../core/haptics/haptics_service.dart';

/// Sound + haptic for every battle moment (SPEC §4.7), driven by the
/// replayed events so the page only says *what* happened.
class BattleFeedback {
  const BattleFeedback({required this.audio, required this.haptics});

  final AudioService audio;
  final HapticsService haptics;

  void _do(Sfx sfx, HapticMoment moment) {
    unawaited(audio.play(sfx));
    unawaited(haptics.play(moment));
  }

  /// Arena music: `battle_loop`, looping, from the pre-battle screen until
  /// the result (a no-op while it already plays; respects the music toggle).
  void enter() => unawaited(audio.playMusic(Music.battleLoop));

  /// Result screen: the music stops (the victory/defeat sound plays alone).
  void resultShown() => unawaited(audio.stopMusic());

  /// Back to the menu: `menu_loop`.
  void leave() => unawaited(audio.playMusic(Music.menuLoop));

  /// Attacker / target selection.
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

  /// One tick of the coin count-up.
  void coinTick() => _do(Sfx.coin, HapticMoment.coin);
}
