import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/core/network/dio_client.dart';
import 'package:portalcards/core/storage/api_data_store.dart';
import 'package:portalcards/core/storage/player_store.dart';
import 'package:portalcards/features/sync/data/remote_data_source.dart';
import 'package:portalcards/features/sync/data/sync_repository_impl.dart';
import 'package:portalcards/features/sync/domain/sync_repository.dart';

import '../../core/network/fake_adapter.dart';
import '../../core/storage/hive_test_helper.dart';
import '../../fixtures/fixtures.dart';
import 'fake_remote.dart';

final DateTime _now = DateTime.utc(2026, 11, 12, 12);

Future<(SyncRepositoryImpl, ApiDataStore, PlayerStore)> _open(
  SyncRemoteDataSource remote,
) async {
  final store = await ApiDataStore.open();
  final player = await PlayerStore.open();
  return (
    SyncRepositoryImpl(
      remote: remote,
      store: store,
      player: player,
      clock: () => _now,
    ),
    store,
    player,
  );
}

Future<void> _closeAll() => Hive.close();

void main() {
  useTempHive();

  // 45 characters = 3 pages, 21 episodes = 2 pages, 5 locations = 1 page.
  const fullOrder = [
    'character 1',
    'episode 1',
    'location 1',
    'character 2',
    'character 3',
    'episode 2',
  ];

  test('full run stores everything, reports progress, marks synced', () async {
    final remote = FakeSyncRemote();
    final (repo, store, player) = await _open(remote);
    final progress = <SyncProgress>[];

    final result = await repo.sync(onProgress: progress.add);

    expect(result, right<Failure, Unit>(unit));
    expect(remote.calls, fullOrder);
    expect(store.characterCount, 45);
    expect(store.episodeCount, 21);
    expect(store.locationCount, 5);
    expect(progress.last, const SyncProgress(downloaded: 71, total: 71));
    expect(progress.last.percent, 100);
    expect(
      progress.map((p) => p.downloaded),
      orderedEquals([...progress.map((p) => p.downloaded)]..sort()),
    );
    expect(player.state.syncVersion, SyncRepositoryImpl.currentSyncVersion);
    expect(player.state.syncedAt, _now);
    expect(player.state.syncTotals, {
      'character': 45,
      'episode': 21,
      'location': 5,
    });
    expect(repo.isSynced, isTrue);
  });

  test(
    'totals of all three resources are known after the first pages',
    () async {
      final (repo, _, _) = await _open(FakeSyncRemote());
      final progress = <SyncProgress>[];

      await repo.sync(onProgress: progress.add);

      // Third report = after location page 1: every total is in.
      expect(progress[2].total, 71);
    },
  );

  test(
    'failure on page 5 keeps pages 1-4, resume fetches no page twice',
    () async {
      final remote = FakeSyncRemote(failOnCall: 5);
      var (repo, store, player) = await _open(remote);

      final failed = await repo.sync(onProgress: (_) {});

      expect(failed, left<Failure, Unit>(const NetworkFailure()));
      expect(remote.calls, fullOrder.take(5));
      expect(store.characterCount, 40); // character pages 1 and 2
      expect(store.episodeCount, 20);
      expect(store.locationCount, 5);
      expect(player.state.syncProgress, {
        'character': 2,
        'episode': 1,
        'location': 1,
      });
      expect(repo.isSynced, isFalse);

      // Relaunch: storage reopened from disk, same remote.
      await _closeAll();
      remote.calls.clear();
      (repo, store, player) = await _open(remote);

      final resumed = await repo.sync(onProgress: (_) {});

      expect(resumed.isRight(), isTrue);
      expect(remote.calls, ['character 3', 'episode 2']);
      expect(store.characterCount, 45);
      expect(store.episodeCount, 21);
      expect(repo.isSynced, isTrue);
    },
  );

  test('a failed first page saves nothing and retries that page', () async {
    final remote = FakeSyncRemote(failOnCall: 1);
    final (repo, store, player) = await _open(remote);

    expect((await repo.sync(onProgress: (_) {})).isLeft(), isTrue);
    expect(store.characterCount, 0);
    expect(player.state.syncProgress, isEmpty);

    remote.calls.clear();
    expect((await repo.sync(onProgress: (_) {})).isRight(), isTrue);
    expect(remote.calls, fullOrder);
  });

  test(
    'already synced: no network call, progress reported as complete',
    () async {
      final remote = FakeSyncRemote();
      var (repo, _, _) = await _open(remote);
      await repo.sync(onProgress: (_) {});
      await _closeAll();

      remote.calls.clear();
      (repo, _, _) = await _open(remote);
      final progress = <SyncProgress>[];

      final result = await repo.sync(onProgress: progress.add);

      expect(result.isRight(), isTrue);
      expect(remote.calls, isEmpty);
      expect(progress.single, const SyncProgress(downloaded: 71, total: 71));
    },
  );

  test('progress fraction and percent', () {
    const p = SyncProgress(downloaded: 1, total: 3);
    expect(p.fraction, closeTo(0.333, 0.001));
    expect(p.percent, 33);
    expect(const SyncProgress(downloaded: 0, total: 0).percent, 0);
  });

  test(
    'ApiSyncRemoteDataSource requests ?page=N and maps the response',
    () async {
      final adapter = FakeAdapter([
        FakeReply(200, loadFixture('episode_page_1.json')),
      ]);
      final remote = ApiSyncRemoteDataSource(ApiClient(adapter: adapter));

      final page = (await remote.episodePage(1))
          .getOrElse((f) => throw StateError('$f'));

      expect(adapter.requests.single.query, 'page=1');
      expect(adapter.requests.single.path, '/api/episode');
      expect(page.count, 51);
      expect(page.items.first.code, 'S01E01');
    },
  );
}
