import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/api_data_store.dart';
import '../../../core/storage/player_store.dart';
import '../domain/sync_repository.dart';
import 'mappers.dart';
import 'remote_data_source.dart';

/// Çekilmiş ve kaydedilmeye hazır bir sayfa.
typedef _Fetched = ({int count, int pages, Future<void> Function() store});

/// Bir API kaynağı ve onun bir sayfasının nasıl çekilip kaydedileceği.
class _Resource {
  const _Resource(this.key, this.fetch);

  final String key;
  final Future<Either<Failure, _Fetched>> Function(int page) fetch;
}

/// Kaldığı yerden devam eden senkron (SPEC §2.1). Sıra: karakterler, bölümler ve
/// konumların 1. sayfası (böylece tüm toplamlar erken bilinir), sonra kalan sayfalar.
/// Her sayfadan sonra: öğeleri yaz, sonra ilerlemeyi kaydet. İlerlemesi
/// kaydedilmiş bir sayfa asla yeniden çekilmez.
class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({
    required this._remote,
    required this._store,
    required this._player,
    this._clock = DateTime.now,
  });

  /// Kayıtlı biçim değişip baştan indirme gerektiğinde artır.
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

      // 1. aşama: her kaynağın ilk sayfası → tüm toplamlar bilinir.
      for (final r in _resources) {
        if (_lastPage(r.key) == 0) {
          final failure = await _fetchAndSave(r, 1, onProgress);
          if (failure != null) return left(failure);
        }
      }
      onProgress(_progress);

      // 2. aşama: kalan sayfalar, son kaydedilenden sonra devam ederek.
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
      // Hive sorunları HiveError olarak bildirir (Exception değil, bir Error).
    } catch (e, stackTrace) {
      AppLogger.error('sync storage error', e, stackTrace);
      return left(StorageFailure(e.runtimeType.toString()));
    }
  }

  /// Başarıda null döner.
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
