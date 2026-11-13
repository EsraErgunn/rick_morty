import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/cards/game_card_data.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/battle_state.dart';

/// Savaş öncesi (SPEC §2.7 AC1): rakibin 3 kartı, oyuncunun destesi,
/// kademe ve galibiyetler ve "Başla".
class PreBattleView extends StatelessWidget {
  const PreBattleView({required this.state, required this.onStart, super.key});

  final BattleViewState state;
  final VoidCallback onStart;

  Widget _team(String title, List<GameCardData> cards, bool fromTop) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, textAlign: TextAlign.center, style: AppTypography.title),
      const SizedBox(height: AppSpacing.xs),
      Row(
        children: [
          for (final (i, c) in cards.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GameCard(data: c)
                  .animate(delay: AppMotion.battleDealStagger * i)
                  .fadeIn(duration: AppMotion.normal)
                  .slideY(
                    begin: fromTop ? -0.3 : 0.3,
                    duration: AppMotion.normal,
                    curve: AppMotion.emerge,
                  ),
            ),
          ],
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _team(l10n.battleOpponent, state.enemyCards, true),
          Text(
            l10n.battleTier(state.tier, state.wins),
            key: const ValueKey('battle-tier'),
            textAlign: TextAlign.center,
            style: AppTypography.label.copyWith(color: AppColors.paperMuted),
          ),
          _team(l10n.battleYourDeck, state.playerCards, false),
          FilledButton(
            key: const ValueKey('battle-start'),
            onPressed: onStart,
            child: Text(l10n.battleStart),
          ),
        ],
      ),
    );
  }
}
