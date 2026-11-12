import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/game/battle_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/battle_repository.dart';

/// Result (SPEC §4.7): "Kazandın!" / "Kaybettin" / "Berabere" pops in, the
/// reward counts up, tier-up note, then "Yeni savaş" / "Menüye dön".
class BattleResultView extends StatelessWidget {
  const BattleResultView({
    required this.result,
    required this.reward,
    required this.onAgain,
    required this.onExit,
    required this.onCoinTick,
    super.key,
  });

  final BattleResult result;
  final BattleReward? reward;
  final VoidCallback onAgain;
  final VoidCallback onExit;
  final VoidCallback onCoinTick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, color) = switch (result) {
      BattleResult.victory => (l10n.battleVictory, AppColors.portal),
      BattleResult.defeat => (l10n.battleDefeat, AppColors.danger),
      BattleResult.draw => (l10n.battleDraw, AppColors.paperMuted),
    };
    final coins = reward?.coins ?? 0;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
                title,
                key: const ValueKey('battle-result'),
                textAlign: TextAlign.center,
                style: AppTypography.callout.copyWith(
                  color: color,
                  shadows: const [
                    Shadow(color: AppColors.ink, offset: AppDepth.shadow),
                  ],
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: AppMotion.slow,
                curve: result == BattleResult.victory
                    ? AppMotion.reward
                    : AppMotion.popIn,
              )
              .fadeIn(duration: AppMotion.fast),
          const SizedBox(height: AppSpacing.lg),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: coins),
            duration: AppMotion.slow,
            curve: AppMotion.move,
            onEnd: onCoinTick,
            builder: (context, v, _) => Text(
              l10n.battleReward(v),
              key: const ValueKey('battle-reward'),
              textAlign: TextAlign.center,
              style: AppTypography.coin,
            ),
          ),
          if (reward case final r? when r.tierUp) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.battleTierUp(r.tierAfter),
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(color: AppColors.portalHot),
            ).animate().fadeIn(delay: AppMotion.slow),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            key: const ValueKey('battle-again'),
            onPressed: onAgain,
            child: Text(l10n.battleAgain),
          ),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton(
            key: const ValueKey('battle-exit'),
            onPressed: onExit,
            child: Text(l10n.battleBackToMenu),
          ),
        ],
      ),
    );
  }
}
