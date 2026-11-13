import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/cards/game_card_data.dart';
import '../../../../core/feedback/ui_feedback.dart';
import '../../../../core/sensors/tilt_stream.dart';
import '../../../../core/widgets/game_card/card_back.dart';
import '../../../../core/widgets/game_card/flip_card.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../../../core/widgets/game_card/holo_layer.dart';
import '../../../../core/widgets/game_card/tilting_game_card.dart';
import '../../../../core/widgets/shader_cache.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/card_detail_bloc.dart';
import '../bloc/card_detail_event.dart';
import '../bloc/card_detail_state.dart';
import '../widgets/collection_grid.dart';
import '../../../../core/widgets/app_back_button.dart';

/// Card detail (SPEC §2.5, §4.5): tilt + holo + flip, back facts, and the
/// deck action. Expects a [CardDetailBloc] above it.
class CardDetailPage extends StatelessWidget {
  const CardDetailPage({
    required this.id,
    required this.tiltStream,
    required this.shaders,
    required this.feedback,
    super.key,
  });

  final int id;
  final TiltStream tiltStream;
  final ShaderCache shaders;
  final UiFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<CardDetailBloc, CardDetailState>(
      builder: (context, state) {
        final card = state.card;
        final title = card?.name ?? l10n.cardDetailTitle('$id');
        return Scaffold(
          appBar: AppBar(
            leading: AppBackButton(onFeedback: feedback.tap),
            title: Text(title),
            actions: [
              if (state.owned)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.gutter),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: AppMotion.normal,
                      transitionBuilder: (child, a) =>
                          ScaleTransition(scale: a, child: child),
                      child: Text(
                        l10n.deckCount(state.deck.length),
                        key: ValueKey(state.deck.length),
                        style: AppTypography.stat,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: card == null
                ? Center(child: Text(title, style: AppTypography.display))
                : Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Center(child: _card(card)),
                        ),
                      ),
                      _DeckAction(state: state, feedback: feedback),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _card(GameCardData card) => Hero(
    tag: cardHeroTag(card.id),
    child: TiltingGameCard(
      tiltStream: tiltStream,
      builder: (context, tilt) => FlipCard(
        onFlipped: (_) => feedback.cardFlip(),
        front: GameCard(
          data: card,
          tilt: tilt,
          holo: HoloLayer(rarity: card.rarity, tilt: tilt, shaders: shaders),
        ),
        back: CardBack(facts: card),
      ),
    ),
  );
}

class _DeckAction extends StatelessWidget {
  const _DeckAction({required this.state, required this.feedback});

  final CardDetailState state;
  final UiFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!state.owned) {
      return Text(l10n.deckNotOwned, style: AppTypography.caption);
    }
    void toggle() {
      feedback.tap();
      context.read<CardDetailBloc>().add(const CardDeckToggled());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: state.inDeck
                ? OutlinedButton(
                    key: const ValueKey('deck-remove'),
                    onPressed: toggle,
                    child: Text(l10n.deckRemove),
                  )
                : FilledButton(
                    key: const ValueKey('deck-add'),
                    onPressed: state.canAdd ? toggle : null,
                    child: Text(l10n.deckAdd),
                  ),
          ),
          if (!state.inDeck && state.deckFull) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(l10n.deckFull, style: AppTypography.caption),
          ],
        ],
      ),
    );
  }
}
