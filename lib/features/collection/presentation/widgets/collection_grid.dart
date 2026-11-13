import 'package:flutter/material.dart';

import '../../../../app/theme/card_style.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../../../core/widgets/floating.dart';
import '../../domain/collection_repository.dart';

/// Izgara hücresi ile kart detayının paylaştığı Hero etiketi (SPEC §4.4).
String cardHeroTag(int id) => 'card-$id';

/// 3'lü tembel ızgara (SPEC §2.4 AC1, AC5); dokununca detay açılır.
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
          child: Floating(
            phase: Floating.phaseFor(i),
            child: RepaintBoundary(child: GameCard(data: card)),
          ),
        ),
      );
    },
  );
}
