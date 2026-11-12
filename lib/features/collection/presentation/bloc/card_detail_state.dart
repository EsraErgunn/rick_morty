import 'package:equatable/equatable.dart';

import '../../../../core/cards/game_card_data.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/collection_repository.dart';

enum CardDetailStatus { initial, success, notFound }

final class CardDetailState extends Equatable {
  const CardDetailState({
    this.status = CardDetailStatus.initial,
    this.card,
    this.owned = false,
    this.deck = const [],
    this.failure,
  });

  final CardDetailStatus status;
  final GameCardData? card;
  final bool owned;
  final List<int> deck;
  final Failure? failure;

  bool get inDeck => card != null && deck.contains(card!.id);
  bool get deckFull => deck.length >= CollectionRepository.deckSize;

  /// The add action is offered only for owned cards and a deck with room.
  bool get canAdd => owned && !inDeck && !deckFull;

  @override
  List<Object?> get props => [status, card, owned, deck, failure];
}
