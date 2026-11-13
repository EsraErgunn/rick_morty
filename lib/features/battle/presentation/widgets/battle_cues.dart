import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/game/battle_model.dart';
import '../../../../core/game/card_type.dart';
import '../../../../core/game/featured.dart';
import '../../../../core/widgets/game_card/card_labels.dart';
import '../../../../l10n/app_localizations.dart';
import 'battle_card_slot.dart';

/// Orta banttaki duyuru ("KRİTİK!", "SÜPER ETKİLİ!" …).
final class BandCue {
  const BandCue(
    this.text, {
    this.color = AppColors.paper,
    this.small = false,
    this.elastic = false,
    this.tick = 0,
  });

  final String text;
  final Color color;

  /// "Pek etkili değil…" küçük ve gridir.
  final bool small;

  /// Süper etkili afişi `elasticOut` ile belirir.
  final bool elastic;
  final int tick;

  BandCue withTick(int t) =>
      BandCue(text, color: color, small: small, elastic: elastic, tick: t);
}

/// Bir slotun bir olay için yaptığı şey.
final class SlotCue {
  const SlotCue(this.motion, [this.popup, this.delay = Duration.zero]);

  final SlotMotion motion;
  final SlotPopup? popup;
  final Duration delay;
}

/// Sahnenin bir olayı nasıl gösterdiği (SPEC §4.7) ve tekrar oynatmayı ne kadar
/// beklettiği (boşluk dahil; bir tur en fazla 1,6 sn sürer).
final class BattleCues {
  const BattleCues({
    required this.duration,
    this.slots = const {},
    this.band,
    this.stageShake = 0,
  });

  final Duration duration;
  final Map<(Side, int), SlotCue> slots;
  final BandCue? band;

  /// Çarpmada ekran sarsıntısı genliği (0: yok).
  final double stageShake;

  static const int _team = 3;

  static BattleCues of(BattleEvent e, AppLocalizations l10n) => switch (e) {
    TurnStarted() => const BattleCues(duration: AppMotion.fast),
    // Vuruş, saldıran hâlâ hedefin üstündeyken başlar.
    Attacked(:final side, :final attacker) => BattleCues(
      duration: AppMotion.battleAttackImpact,
      slots: {(side, attacker): const SlotCue(SlotMotion.lunge)},
    ),
    Dodged(:final side, :final index) => BattleCues(
      duration: AppMotion.battleHit,
      slots: {(side, index): const SlotCue(SlotMotion.dodge)},
      band: BandCue(l10n.battleDodge, color: AppColors.portalHot),
    ),
    Damaged() => _damage(e, l10n),
    Fainted() => const BattleCues(duration: AppMotion.battleFaint),
    Revived(:final side, :final index) => BattleCues(
      duration: AppMotion.slow,
      slots: {(side, index): const SlotCue(SlotMotion.revive)},
      band: BandCue(l10n.battleRevive, color: AppColors.portal),
    ),
    SignatureTriggered(:final signature) =>
      signature == Signature.genius
          ? const BattleCues(duration: Duration.zero)
          : BattleCues(
              duration: AppMotion.normal,
              band: BandCue(
                signature == Signature.missionComplete
                    ? '${l10n.signatureName(signature)}!'
                    : l10n.signatureName(signature),
                color: AppColors.rarityLegendary,
              ),
            ),
    Healed(:final side, :final index, :final amount) => BattleCues(
      duration: AppMotion.normal,
      slots: {
        (side, index): SlotCue(
          SlotMotion.none,
          SlotPopup('+$amount', color: AppColors.portal),
        ),
      },
    ),
    TurnEnded() => const BattleCues(duration: AppMotion.stagger),
    BattleEnded(:final result) => _ended(result),
  };

  /// Kazananlar birbiri ardına zıplar, kaybedenler bir yenilgi işareti alır
  /// (yalnızca Rick'in 2.5D kartı gösterir); beraberlikte hiçbir şey yok. Bekleme
  /// Rick'in tepkisini kapsar.
  static BattleCues _ended(BattleResult result) {
    final winner = switch (result) {
      BattleResult.victory => Side.player,
      BattleResult.defeat => Side.enemy,
      BattleResult.draw => null,
    };
    final loser = switch (winner) {
      Side.player => Side.enemy,
      Side.enemy => Side.player,
      null => null,
    };
    return BattleCues(
      duration:
          AppMotion.battleRickReaction + AppMotion.battleVictoryStagger * 2,
      slots: {
        if (winner != null)
          for (var i = 0; i < _team; i++)
            (winner, i): SlotCue(
              SlotMotion.victory,
              null,
              AppMotion.battleVictoryStagger * i,
            ),
        if (loser != null)
          for (var i = 0; i < _team; i++)
            (loser, i): SlotCue(
              SlotMotion.defeat,
              null,
              AppMotion.battleVictoryStagger * i,
            ),
      },
    );
  }

  static BattleCues _damage(Damaged e, AppLocalizations l10n) {
    final band = switch (e) {
      Damaged(isCrit: true, signature: Signature.genius) => BandCue(
        l10n.battleGenius,
        color: AppColors.rarityLegendary,
      ),
      Damaged(isCrit: true) => BandCue(l10n.battleCrit, color: AppColors.warn),
      Damaged(effectiveness: Effectiveness.superEffective) => BandCue(
        l10n.battleSuperEffective,
        color: AppColors.portal,
        elastic: true,
      ),
      Damaged(effectiveness: Effectiveness.notVeryEffective) => BandCue(
        l10n.battleNotEffective,
        color: AppColors.paperMuted,
        small: true,
      ),
      _ => null,
    };
    final heavy = e.isCrit || e.effectiveness == Effectiveness.superEffective;
    return BattleCues(
      duration: heavy ? AppMotion.battleHeavyHit : AppMotion.battleHit,
      stageShake: heavy
          ? AppSizes.battleStageCritShake
          : AppSizes.battleStageShake,
      slots: {
        (e.side, e.index): SlotCue(
          heavy ? SlotMotion.heavyShake : SlotMotion.shake,
          SlotPopup(
            '-${e.amount}',
            color: e.isCrit ? AppColors.warn : AppColors.paper,
            big: e.isCrit,
          ),
        ),
      },
      band: band,
    );
  }
}
