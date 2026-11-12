import 'package:flutter/material.dart';

import '../../core/cards/game_card_data.dart';
import '../../core/widgets/game_card/card_back.dart';
import '../../core/widgets/game_card/flip_card.dart';
import '../../core/widgets/game_card/game_card.dart';
import '../../l10n/app_localizations.dart';
import '../theme/card_style.dart';
import '../theme/spacing.dart';

/// Debug-only screen (`/debug/card-lab`, registered only in debug builds):
/// real synced characters through `CardFactory`, one per rarity and type.
/// Tap a card to flip it.
class CardLabPage extends StatelessWidget {
  const CardLabPage({required this.cards, super.key});

  final List<GameCardData> cards;

  /// The ids of the test fixtures: all rarities, types and statuses.
  static const List<int> characterIds = [1, 2, 23, 63, 71, 82, 86, 309];

  static const int _columns = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cardLabTitle)),
      body: cards.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text(l10n.cardLabEmpty, textAlign: TextAlign.center),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: CardMetrics.aspect,
              ),
              itemCount: cards.length,
              itemBuilder: (context, i) => FlipCard(
                front: GameCard(data: cards[i]),
                back: CardBack(facts: cards[i]),
              ),
            ),
    );
  }
}
