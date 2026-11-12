import 'package:fpdart/fpdart.dart';

import '../../../core/cards/card_factory.dart';
import '../../../core/cards/game_card_data.dart';
import '../../../core/errors/failures.dart';
import '../../../core/storage/api_data_store.dart';
import '../../../core/storage/player_store.dart';
import '../domain/collection_repository.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  const CollectionRepositoryImpl({
    required this._apiData,
    required this._player,
    required this._collection,
  });

  final ApiDataStore _apiData;
  final PlayerStore _player;
  final CollectionStore _collection;

  @override
  List<CollectionEntry> entries() => [
    for (final owned in _collection.cards)
      if (card(owned.characterId) case final c?)
        CollectionEntry(
          card: c,
          copies: owned.copies,
          obtainedAt: owned.firstObtainedAt,
        ),
  ];

  @override
  int get totalCharacters => _apiData.characterCount;

  @override
  GameCardData? card(int id) => switch (_apiData.character(id)) {
    final c? => CardFactory.fromCharacter(c),
    null => null,
  };

  @override
  bool owns(int id) => _collection.owns(id);

  @override
  List<int> get deck => List.unmodifiable(_player.state.deck);

  @override
  Future<Either<Failure, List<int>>> toggleDeck(int id) async {
    final deck = [..._player.state.deck];
    if (deck.contains(id)) {
      deck.remove(id);
    } else {
      if (!owns(id)) return left(const StorageFailure('not owned'));
      if (deck.length >= CollectionRepository.deckSize) {
        return left(const DeckFullFailure());
      }
      deck.add(id);
    }
    try {
      await _player.update((s) => s.copyWith(deck: deck));
    } on Object catch (e) {
      return left(StorageFailure(e.runtimeType.toString()));
    }
    return right(List.unmodifiable(deck));
  }
}
