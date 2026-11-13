import 'package:flutter/material.dart';

import '../../../../app/theme/card_style.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/deck_state.dart';

/// Üç slot (SPEC §2.6 AC1, §4.6): kart `easeOutBack` ile düşer;
/// deste tamamlanınca slotların çevresi bir kez portal yeşiline boyanır.
class DeckSlots extends StatelessWidget {
  const DeckSlots({required this.state, required this.onSlot, super.key});

  final DeckState state;
  final ValueChanged<int> onSlot;

  @override
  Widget build(BuildContext context) {
    final flash = state.change == DeckChange.completed && state.complete;
    return TweenAnimationBuilder<double>(
      key: ValueKey('flash-${state.changeTick}-$flash'),
      tween: Tween(begin: flash ? 1 : 0, end: 0),
      duration: AppMotion.slow,
      builder: (context, glow, _) => Row(
        children: [
          for (var i = 0; i < DeckState.size; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GestureDetector(
                key: ValueKey('slot-$i'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onSlot(i),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.cardAll,
                    border: Border.all(
                      color: Color.lerp(AppColors.ink, AppColors.portal, glow)!,
                      width: AppOutline.thick + 2 * glow,
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: CardMetrics.aspect,
                    child: AnimatedSwitcher(
                      duration: AppMotion.normal,
                      switchInCurve: AppMotion.popIn,
                      switchOutCurve: AppMotion.move,
                      transitionBuilder: (child, a) => ScaleTransition(
                        scale: a,
                        child: FadeTransition(opacity: a, child: child),
                      ),
                      child: switch (state.slot(i)) {
                        final card? => GameCard(
                          key: ValueKey('slot-card-${card.id}'),
                          data: card,
                        ),
                        null => Center(
                          key: ValueKey('slot-empty-$i'),
                          child: Text(
                            AppLocalizations.of(context).deckSlotEmpty,
                            style: AppTypography.caption,
                          ),
                        ),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
