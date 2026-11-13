import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/cards/game_card_data.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../../../l10n/app_localizations.dart';
import 'loop_builder.dart';

/// Page 4: two cards clash, then the reward rises: "+coin".
class BattleSlideArt extends StatelessWidget {
  const BattleSlideArt({required this.cards, super.key});

  /// Showcase cards; the first and the last fight (may be empty).
  final List<GameCardData> cards;

  static const int _reward = 50;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LoopBuilder(
      restAt: 0.7,
      builder: (context, t) {
        // 0..0.4 dash in and hit, 0.4..0.6 back, 0.5..1 reward floats up.
        final clash = math.sin(math.pi * (t / 0.6).clamp(0.0, 1.0));
        final reward = ((t - 0.5) / 0.5).clamp(0.0, 1.0);
        final dash = AppSizes.battleDash * 0.5 * clash;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: const Alignment(-0.8, 0.2),
              child: Transform.translate(
                offset: Offset(dash, 0),
                child: _fighter(cards.isEmpty ? null : cards.first),
              ),
            ),
            Align(
              alignment: const Alignment(0.8, 0.2),
              child: Transform.translate(
                offset: Offset(-dash, 0),
                child: _fighter(cards.isEmpty ? null : cards.last),
              ),
            ),
            if (reward > 0)
              Align(
                alignment: const Alignment(0, -0.6),
                child: Opacity(
                  opacity: math.sin(math.pi * reward),
                  child: Transform.translate(
                    offset: Offset(0, -AppSizes.battleNumberRise * reward),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.toll,
                          color: AppColors.rarityLegendary,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          l10n.battleReward(_reward),
                          style: AppTypography.coin.copyWith(
                            color: AppColors.rarityLegendary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _fighter(GameCardData? card) => SizedBox(
    width: AppSizes.onboardingCard,
    child: card == null
        ? const Icon(
            Icons.sports_martial_arts,
            size: AppSizes.onboardingCard,
            color: AppColors.paper,
          )
        : GameCard(data: card),
  );
}
