import 'package:equatable/equatable.dart';

/// What the main menu shows (SPEC §2.2, §5.6).
final class MenuSummary extends Equatable {
  const MenuSummary({
    required this.coins,
    required this.owned,
    required this.totalCharacters,
    required this.deckSize,
    required this.albumsCompleted,
    required this.albumsTotal,
  });

  final int coins;
  final int owned;
  final int totalCharacters;
  final int deckSize;
  final int albumsCompleted;
  final int albumsTotal;

  static const int fullDeck = 3;

  bool get deckReady => deckSize >= fullDeck;
  bool get collectionEmpty => owned == 0;

  @override
  List<Object?> get props => [
    coins,
    owned,
    totalCharacters,
    deckSize,
    albumsCompleted,
    albumsTotal,
  ];
}

abstract interface class MenuRepository {
  MenuSummary load();
}
