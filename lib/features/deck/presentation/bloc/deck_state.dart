import 'package:equatable/equatable.dart';

import '../../../../core/cards/game_card_data.dart';
import '../../../../core/game/card_type.dart';
import '../../../collection/domain/collection_repository.dart';

enum DeckStatus { initial, success }

/// What changed last, for the page's sound/haptic listener.
enum DeckChange { none, added, removed, completed }

final class DeckState extends Equatable {
  const DeckState({
    this.status = DeckStatus.initial,
    this.owned = const [],
    this.deck = const [],
    this.change = DeckChange.none,
    this.changeTick = 0,
  });

  final DeckStatus status;
  final List<GameCardData> owned;

  /// Deck card ids in slot order (max 3).
  final List<int> deck;
  final DeckChange change;
  final int changeTick;

  static const int size = CollectionRepository.deckSize;

  bool get complete => deck.length == size;

  /// Slot i's card or null.
  GameCardData? slot(int i) {
    if (i >= deck.length) return null;
    for (final c in owned) {
      if (c.id == deck[i]) return c;
    }
    return null;
  }

  List<GameCardData> get deckCards => [
    for (var i = 0; i < deck.length; i++) ?slot(i),
  ];

  int get totalHp => deckCards.fold(0, (s, c) => s + c.stats.hp);
  int get totalAtk => deckCards.fold(0, (s, c) => s + c.stats.atk);
  int get totalDef => deckCards.fold(0, (s, c) => s + c.stats.def);
  int get averageSpd => deckCards.isEmpty
      ? 0
      : (deckCards.fold(0, (s, c) => s + c.stats.spd) / deckCards.length)
            .round();

  /// Which corners of the Human → Robot → Alien triangle the deck has.
  Set<CardType> get coverage => {
    for (final c in deckCards)
      if (c.type == CardType.human ||
          c.type == CardType.robot ||
          c.type == CardType.alien)
        c.type,
  };

  DeckState copyWith({
    DeckStatus? status,
    List<GameCardData>? owned,
    List<int>? deck,
    DeckChange? change,
    int? changeTick,
  }) => DeckState(
    status: status ?? this.status,
    owned: owned ?? this.owned,
    deck: deck ?? this.deck,
    change: change ?? this.change,
    changeTick: changeTick ?? this.changeTick,
  );

  @override
  List<Object?> get props => [status, owned, deck, change, changeTick];
}
