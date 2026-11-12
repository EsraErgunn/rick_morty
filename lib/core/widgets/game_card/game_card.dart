import 'package:flutter/material.dart';

import '../../../app/theme/card_style.dart';
import '../../cards/game_card_data.dart';
import 'card_front.dart';

/// A 5:7 card. Laid out at [CardMetrics] design size and scaled to the
/// space it gets, so it looks the same in a grid and on the detail page.
class GameCard extends StatelessWidget {
  const GameCard({required this.data, super.key});

  final GameCardData data;

  @override
  Widget build(BuildContext context) => CardSizer(child: CardFront(data: data));
}

/// Scales a design-size card face to the available space (5:7).
class CardSizer extends StatelessWidget {
  const CardSizer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: CardMetrics.aspect,
    child: FittedBox(
      child: SizedBox(
        width: CardMetrics.designWidth,
        height: CardMetrics.designHeight,
        child: child,
      ),
    ),
  );
}
