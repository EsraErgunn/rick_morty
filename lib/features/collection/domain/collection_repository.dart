import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/cards/game_card_data.dart';
import '../../../core/errors/failures.dart';

/// One owned card.
final class CollectionEntry extends Equatable {
  const CollectionEntry({
    required this.card,
    required this.copies,
    required this.obtainedAt,
  });

  final GameCardData card;
  final int copies;
  final DateTime obtainedAt;

  @override
  List<Object?> get props => [card, copies, obtainedAt];
}

abstract interface class CollectionRepository {
  static const int deckSize = 3;

  List<CollectionEntry> entries();

  /// Fires whenever the stored data behind this repository changes.
  Stream<void> get changes;

  int get totalCharacters;

  /// Any synced character (card lab and detail), owned or not.
  GameCardData? card(int id);
  bool owns(int id);
  List<int> get deck;

  /// Adds [id] to the deck, or removes it if it is already in.
  /// [DeckFullFailure] when adding to a full deck (nothing changes).
  Future<Either<Failure, List<int>>> toggleDeck(int id);
}
