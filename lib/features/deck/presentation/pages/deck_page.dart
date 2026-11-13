import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/card_style.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/feedback/ui_feedback.dart';
import '../../../../core/game/card_type.dart';
import '../../../../core/widgets/game_card/card_labels.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../../../core/widgets/floating.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/deck_bloc.dart';
import '../bloc/deck_event.dart';
import '../bloc/deck_state.dart';
import '../widgets/deck_slots.dart';
import '../../../../core/widgets/app_back_button.dart';

/// Deck builder (SPEC §2.6, §4.6). Expects a [DeckBloc] above it.
class DeckPage extends StatelessWidget {
  const DeckPage({required this.feedback, super.key});

  final UiFeedback feedback;

  static const int _columns = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<DeckBloc>();
    return BlocConsumer<DeckBloc, DeckState>(
      listenWhen: (a, b) => a.changeTick != b.changeTick,
      listener: (context, state) => switch (state.change) {
        DeckChange.added => feedback.cardFlip(),
        DeckChange.removed => feedback.tap(),
        DeckChange.completed => feedback.success(),
        DeckChange.none => null,
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          leading: AppBackButton(onFeedback: feedback.tap),
          title: Text(l10n.deckTitle),
        ),
        body: state.owned.isEmpty
            ? Center(
                child: Text(
                  l10n.deckNoCards,
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DeckSlots(
                      state: state,
                      onSlot: (i) => bloc.add(DeckSlotTapped(i)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.deckTotals(
                        state.totalHp,
                        state.totalAtk,
                        state.totalDef,
                        state.averageSpd,
                      ),
                      key: const ValueKey('deck-totals'),
                      textAlign: TextAlign.center,
                      style: AppTypography.stat,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _Coverage(types: state.coverage),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.deckHint,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _columns,
                              mainAxisSpacing: AppSpacing.xs,
                              crossAxisSpacing: AppSpacing.xs,
                              childAspectRatio: CardMetrics.aspect,
                            ),
                        itemCount: state.owned.length,
                        itemBuilder: (context, i) {
                          final card = state.owned[i];
                          final inDeck = state.deck.contains(card.id);
                          return GestureDetector(
                            key: ValueKey('owned-${card.id}'),
                            onTap: () => bloc.add(DeckCardTapped(card.id)),
                            child: Floating(
                              phase: Floating.phaseFor(i),
                              child: Opacity(
                                opacity: inDeck ? 0.35 : 1,
                                child: GameCard(data: card),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Human → Robot → Alien corners present in the deck (SPEC §2.6 AC3).
class _Coverage extends StatelessWidget {
  const _Coverage({required this.types});

  final Set<CardType> types;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [
        Text(l10n.deckCoverage, style: AppTypography.caption),
        for (final t in const [CardType.human, CardType.robot, CardType.alien])
          Chip(
            key: ValueKey('coverage-${t.name}-${types.contains(t)}'),
            avatar: Icon(CardTypeIcons.of(t), size: AppSizes.iconSmall),
            label: Text(l10n.typeName(t)),
            backgroundColor: types.contains(t)
                ? AppColors.portal
                : AppColors.voidRaised,
            labelStyle: AppTypography.caption.copyWith(
              color: types.contains(t) ? AppColors.ink : AppColors.paperMuted,
            ),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
