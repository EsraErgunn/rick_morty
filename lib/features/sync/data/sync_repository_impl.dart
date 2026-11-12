import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/api_data_store.dart';
import '../../../core/storage/player_store.dart';
import '../domain/sync_repository.dart';
import 'mappers.dart';
import 'remote_data_source.dart';

/// A page fetched and ready to store.
typedef _Fetched = ({int count, int pages, Future<void> Function() store});

/// One API resource and how to fetch and store a page of it.
class _Resource {
  const _Resource(this.key, this.fetch);

  final String key;
  final Future<Either<Failure, _Fetched>> Function(int page) fetch;
}

/// Resumable sync (SPEC §2.1). Order: page 1 of characters, episodes and
/// locations (so all totals are known early), then the remaining pages.
/// After each page: write the items, then save the progress. A page is
/// never fetched again once its progress is saved.
class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({
    required this._remote,
    required this._store,
    required this._player,
    this._clock = DateTime.now,
  });

  /// Bump when the stored shape changes and a fresh download is needed.
  static const int currentSyncVersion = 1;

  static const String characterKey = 'character';
  static const String episodeKey = 'episode';
  static const String locationKey = 'location';

  final SyncRemoteDataSource _remote;
  final ApiDataStore _store;
  final PlayerStore _player;
  final DateTime Function() _clock;

  late final List<_Resource> _resources = [
    _Resource(
      characterKey,
      (p) async => (await _remote.characterPage(
        p,
      )).map((page) => _fetched(page, () => _store.putCharacters(page.items))),
    ),
    _Resource(
      episodeKey,
      (p) async => (await _remote.episodePage(p))
          .map((page) => _fetched(page, () => _store.putEpisodes(page.items))),
    ),
    _Resource(
      locationKey,
      (p) async => (await _remote.locationPage(p))
          .map((page) => _fetched(page, () => _store.putLocations(page.items))),
    ),
  ];

  static _Fetched _fetched<T>(
    EntityPage<T> page,
    Future<void> Function() store,
  ) => (count: page.count, pages: page.pages, store: store);

  @override
  bool get isSynced =>
      _player.state.isSynced &&
      _player.state.syncVersion! >= currentSyncVersion;

  SyncProgress get _progress => SyncProgress(
    downloaded:
        _store.characterCount + _store.episodeCount + _store.locationCount,
    total: _player.state.syncTotals.values.fold(0, (a, b) => a + b),
  );

  int _lastPage(String key) => _player.state.syncProgress[key] ?? 0;

  @override
  Future<Either<Failure, Unit>> sync({
    required void Function(SyncProgress progress) onProgress,
  }) async {
    try {
      if (isSynced) {
        onProgress(_progress);
        return right(unit);
      }

      // Phase 1: first page of each resource → all totals known.
      for (final r in _resources) {
        if (_lastPage(r.key) == 0) {
          final failure = await _fetchAndSave(r, 1, onProgress);
          if (failure != null) return left(failure);
        }
      }
      onProgress(_progress);

      // Phase 2: remaining pages, resuming after the last saved one.
      for (final r in _resources) {
        final pages = _player.state.syncPages[r.key]!;
        for (var page = _lastPage(r.key) + 1; page <= pages; page++) {
          final failure = await _fetchAndSave(r, page, onProgress);
          if (failure != null) return left(failure);
        }
      }

      await _player.update(
        (s) => s.copyWith(syncVersion: currentSyncVersion, syncedAt: _clock()),
      );
      AppLogger.info('sync complete: ${_progress.downloaded} items');
      onProgress(_progress);
      return right(unit);
      // Hive reports problems as HiveError (an Error, not an Exception).
    } catch (e, stackTrace) {
      AppLogger.error('sync storage error', e, stackTrace);
      return left(StorageFailure(e.runtimeType.toString()));
    }
  }

  /// Returns null on success.
  Future<Failure?> _fetchAndSave(
    _Resource r,
    int page,
    void Function(SyncProgress) onProgress,
  ) async {
    final result = await r.fetch(page);
    switch (result) {
      case Left(value: final failure):
        AppLogger.warning('sync ${r.key} page $page failed', failure);
        return failure;
      case Right(value: final fetched):
        await fetched.store();
        await _player.update(
          (s) => s.copyWith(
            syncProgress: {...s.syncProgress, r.key: page},
            syncTotals: {...s.syncTotals, r.key: fetched.count},
            syncPages: {...s.syncPages, r.key: fetched.pages},
          ),
        );
        onProgress(_progress);
        return null;
    }
  }
}
