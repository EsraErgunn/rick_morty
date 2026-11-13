import '../../../core/cards/card_factory.dart';
import '../../../core/entities/episode.dart';
import '../../../core/game/economy.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/api_data_store.dart';
import '../../../core/storage/player_store.dart';
import '../../../core/storage/store_changes.dart';
import '../domain/album_repository.dart';

class AlbumRepositoryImpl implements AlbumRepository {
  AlbumRepositoryImpl({
    required this._apiData,
    required this._player,
    required this._collection,
  });

  final ApiDataStore _apiData;
  final PlayerStore _player;
  final CollectionStore _collection;

  /// Claims run one after another, so two change events can never pay the
  /// same episode twice.
  Future<List<AlbumReward>> _claims = Future.value(const []);

  /// Characters the album can show (synced ones only).
  List<int> _members(Episode e) => [
    for (final id in e.characterIds)
      if (_apiData.character(id) != null) id,
  ];

  AlbumEpisode _summary(Episode e, Set<int> owned) {
    final members = _members(e);
    return AlbumEpisode(
      id: e.id,
      code: e.code,
      name: e.name,
      owned: members.where(owned.contains).length,
      total: members.length,
    );
  }

  @override
  List<AlbumEpisode> episodes() {
    final owned = _collection.ownedIds;
    return [for (final e in _apiData.episodes) _summary(e, owned)]
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  @override
  AlbumEpisode? episode(int id) => switch (_apiData.episode(id)) {
    final e? => _summary(e, _collection.ownedIds),
    null => null,
  };

  @override
  List<AlbumMember> members(int episodeId) {
    final e = _apiData.episode(episodeId);
    if (e == null) return const [];
    return [
      for (final id in _members(e))
        AlbumMember(
          card: CardFactory.fromCharacter(_apiData.character(id)!),
          owned: _collection.owns(id),
        ),
    ];
  }

  @override
  Future<List<AlbumReward>> claimCompleted() =>
      _claims = _claims.then((_) => _claim(), onError: (_) => _claim());

  Future<List<AlbumReward>> _claim() async {
    final paid = _player.state.completedAlbums.toSet();
    final due = [
      for (final e in episodes())
        if (e.complete && !paid.contains(e.id)) e,
    ];
    if (due.isEmpty) return const [];
    final rewards = [
      for (final e in due)
        AlbumReward(code: e.code, coins: Economy.albumCoins(e.total)),
    ];
    await _player.update((s) {
      var coins = s.coins;
      for (final r in rewards) {
        final t = Economy.earn(coins, r.coins, CoinReason.album);
        AppLogger.info(t.toString());
        coins = t.after;
      }
      return s.copyWith(
        coins: coins,
        completedAlbums: [...s.completedAlbums, for (final e in due) e.id],
      );
    });
    return rewards;
  }

  @override
  Stream<void> get changes =>
      mergeChanges([_player.changes, _collection.changes]);
}
