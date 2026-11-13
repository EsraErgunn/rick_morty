import 'package:flutter/material.dart';

import '../../core/cards/game_card_data.dart';
import '../../core/widgets/game_card/card_back.dart';
import '../../core/widgets/game_card/flip_card.dart';
import '../../core/widgets/game_card/game_card.dart';
import '../../l10n/app_localizations.dart';
import '../theme/card_style.dart';
import '../theme/spacing.dart';

/// Yalnızca debug ekranı (`/debug/card-lab`, sadece debug derlemede kayıtlı):
/// `CardFactory` ile gerçek senkronlanmış karakterler, her nadirlik ve tipten bir tane.
/// Karta dokununca döner; uzun basınca detay sayfası açılır.
class CardLabPage extends StatelessWidget {
  const CardLabPage({required this.cards, this.onOpen, super.key});

  final List<GameCardData> cards;

  /// Uzun basma: kart detayını açar (eğim + holo).
  final ValueChanged<int>? onOpen;

  /// Test fikstürlerinin id'leri: tüm nadirlikler, tipler ve durumlar.
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
              itemBuilder: (context, i) => GestureDetector(
                onLongPress: () => onOpen?.call(cards[i].id),
                child: FlipCard(
                  front: GameCard(data: cards[i]),
                  back: CardBack(facts: cards[i]),
                ),
              ),
            ),
    );
  }
}
