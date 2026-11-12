import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../core/game/battle_model.dart';
import '../../../../core/game/card_type.dart';
import '../../../../core/game/featured.dart';
import '../../../../core/widgets/game_card/card_labels.dart';
import '../../../../l10n/app_localizations.dart';
import 'battle_card_slot.dart';

/// A callout in the middle band ("KRİTİK!", "SÜPER ETKİLİ!" …).
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

  /// "Pek etkili değil…" is small and grey.
  final bool small;

  /// The super-effective banner pops with `elasticOut`.
  final bool elastic;
  final int tick;

  BandCue withTick(int t) =>
      BandCue(text, color: color, small: small, elastic: elastic, tick: t);
}

/// What one slot does for an event.
final class SlotCue {
  const SlotCue(this.motion, [this.popup]);

  final SlotMotion motion;
  final SlotPopup? popup;
}

/// How the stage shows one event (SPEC §4.7) and how long it holds the
/// replay (gap included; a whole turn stays ≤ 1.6 s).
final class BattleCues {
  const BattleCues({required this.duration, this.slots = const {}, this.band});

  final Duration duration;
  final Map<(Side, int), SlotCue> slots;
  final BandCue? band;

  static BattleCues of(BattleEvent e, AppLocalizations l10n) => switch (e) {
    TurnStarted() => const BattleCues(duration: AppMotion.fast),
    Attacked(:final side, :final attacker) => BattleCues(
      duration: AppMotion.normal,
      slots: {(side, attacker): const SlotCue(SlotMotion.lunge)},
    ),
    Dodged(:final side, :final index) => BattleCues(
      duration: AppMotion.battleHit,
      slots: {(side, index): const SlotCue(SlotMotion.dodge)},
      band: BandCue(l10n.battleDodge, color: AppColors.portalHot),
    ),
    Damaged() => _damage(e, l10n),
    Fainted() => const BattleCues(duration: AppMotion.battleHit),
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
    BattleEnded() => const BattleCues(duration: AppMotion.slow),
  };

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
    return BattleCues(
      duration: AppMotion.battleHit,
      slots: {
        (e.side, e.index): SlotCue(
          SlotMotion.shake,
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
