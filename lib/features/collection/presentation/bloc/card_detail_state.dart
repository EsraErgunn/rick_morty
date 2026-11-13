import 'package:equatable/equatable.dart';

import '../../../../core/cards/game_card_data.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/collection_repository.dart';

/// Kart detayının yüklenme durumu (kart bulunamazsa notFound).
enum CardDetailStatus { initial, success, notFound }

/// Kart detay ekranının durumu: kart, sahiplik ve deste bilgisi.
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

  /// Ekleme işlemi yalnızca sahip olunan kartlarda ve destede yer varsa sunulur.
  bool get canAdd => owned && !inDeck && !deckFull;

  @override
  List<Object?> get props => [status, card, owned, deck, failure];
}
