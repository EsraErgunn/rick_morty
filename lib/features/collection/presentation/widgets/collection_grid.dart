import 'package:flutter/material.dart';

import '../../../../app/theme/card_style.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../domain/collection_repository.dart';

/// Hero tag shared by the grid cell and the card detail (SPEC §4.4).
String cardHeroTag(int id) => 'card-$id';

/// Lazy grid of 3 (SPEC §2.4 AC1, AC5); tap opens the detail.
class CollectionGrid extends StatelessWidget {
  const CollectionGrid({
    required this.entries,
    required this.onOpen,
    super.key,
  });

  final List<CollectionEntry> entries;
  final ValueChanged<int> onOpen;

  static const int columns = 3;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(AppSpacing.gutter),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: CardMetrics.aspect,
    ),
    itemCount: entries.length,
    itemBuilder: (context, i) {
      final card = entries[i].card;
      return GestureDetector(
        key: ValueKey('grid-${card.id}'),
        onTap: () => onOpen(card.id),
        child: Hero(
          tag: cardHeroTag(card.id),
          child: RepaintBoundary(child: GameCard(data: card)),
        ),
      );
    },
  );
}
