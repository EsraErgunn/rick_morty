import '../../../core/storage/api_data_store.dart';
import '../../../core/storage/player_store.dart';
import '../domain/menu_repository.dart';

class MenuRepositoryImpl implements MenuRepository {
  const MenuRepositoryImpl({
    required this._apiData,
    required this._player,
    required this._collection,
  });

  final ApiDataStore _apiData;
  final PlayerStore _player;
  final CollectionStore _collection;

  @override
  MenuSummary load() {
    final state = _player.state;
    return MenuSummary(
      coins: state.coins,
      owned: _collection.ownedIds.length,
      totalCharacters: _apiData.characterCount,
      deckSize: state.deck.length,
      albumsCompleted: state.completedAlbums.length,
      albumsTotal: _apiData.episodeCount,
    );
  }
}
