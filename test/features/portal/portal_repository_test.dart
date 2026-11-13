import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:portalcards/core/cards/rarity_pool.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/core/game/rarity.dart';
import 'package:portalcards/core/storage/api_data_store.dart';
import 'package:portalcards/core/storage/player_store.dart';
import 'package:portalcards/features/portal/data/portal_repository_impl.dart';
import 'package:portalcards/features/sync/data/mappers.dart';

import '../../core/storage/hive_test_helper.dart';
import '../../fixtures/fixtures.dart';

final _now = DateTime.utc(2026, 11, 12);

void main() {
  useTempHive();

  late ApiDataStore apiData;
  late PlayerStore player;
  late CollectionStore collection;
  late RarityPool pool;

  setUp(() async {
    apiData = await ApiDataStore.open();
    final characters = [
      for (final id in characterFixtures.keys)
        parseCharacter(loadCharacter(id))
            .getOrElse((f) => throw StateError('$f')),
      // Fikstürlerde yalnızca 2 sıradan kart var; gerçek veride yüzlerce. Conroy'un
      // beş tek bölümlük kopyası sıradan havuzu gerçekçi tutar.
      for (var id = 9001; id <= 9005; id++)
        parseCharacter(loadCharacter(71)..['id'] = id)
            .getOrElse((f) => throw StateError('$f')),
    ];
    await apiData.putCharacters(characters);
    player = await PlayerStore.open();
    collection = await CollectionStore.open();
    pool = RarityPool.fromCharacters(characters);
  });

  PortalRepositoryImpl repo([int seed = 1]) => PortalRepositoryImpl(
    apiData: apiData,
    player: player,
    collection: collection,
    pool: pool,
    random: Random(seed),
    clock: () => _now,
  );

  test('not enough coins: NotEnoughCoinsFailure, nothing changes', () async {
    await player.update((s) => s.copyWith(coins: 99));
    final before = player.state;

    final result = await repo().open();

    expect(result.getLeft().toNullable(), const NotEnoughCoinsFailure(100, 99));
    expect(player.state, before);
    expect(collection.ownedIds, isEmpty);
  });

  test('a portal spends 100, saves the card and counts the portal', () async {
    final result = (await repo().open()).getOrElse(
      (f) => throw StateError('$f'),
    );

    expect(result.coinsBefore, 300);
    expect(result.coinsAfter, 200);
    expect(result.isDuplicate, isFalse);
    expect(player.state.coins, 200);
    expect(player.state.portalsOpened, 1);
    expect(player.state.shakeHintSeen, isTrue);
    expect(collection.owns(result.card.id), isTrue);
  });

  test('saved before returning: a reopened store has the result', () async {
    final result = (await repo().open()).getOrElse(
      (f) => throw StateError('$f'),
    );
    await Hive.close();
    final p = await PlayerStore.open();
    final c = await CollectionStore.open();
    expect(p.state.coins, 200);
    expect(c.owns(result.card.id), isTrue);
  });

  test('first three portals give three different cards (any seed)', () async {
    for (var seed = 0; seed < 30; seed++) {
      await collection.clear();
      await player.save(player.state.copyWith(coins: 300, portalsOpened: 0));
      final r = repo(seed);
      final ids = <int>{};
      for (var i = 0; i < 3; i++) {
        final result = (await r.open()).getOrElse(
          (f) => throw StateError('$f'),
        );
        expect(result.isDuplicate, isFalse);
        ids.add(result.card.id);
      }
      expect(ids, hasLength(3), reason: 'seed $seed');
      expect(player.state.coins, 0);
    }
  });

  test('a duplicate pays coins by rarity and counts a copy', () async {
    for (final r in Rarity.values) {
      for (final id in pool.ids(r)) {
        await collection.addCopy(id, _now);
      }
    }
    await player.save(player.state.copyWith(portalsOpened: 10));

    final result = (await repo().open()).getOrElse(
      (f) => throw StateError('$f'),
    );

    expect(result.isDuplicate, isTrue);
    final expected = switch (result.card.rarity) {
      Rarity.common => 20,
      Rarity.rare => 40,
      Rarity.epic => 80,
      Rarity.legendary => 200,
    };
    expect(result.duplicateCoins, expected);
    expect(player.state.coins, 200 + expected);
    expect(collection.copiesOf(result.card.id), 2);
  });

  test('demo override gives a legendary once, then disarms', () async {
    await player.save(player.state.copyWith(forceNextLegendary: true));

    final result = (await repo().open()).getOrElse(
      (f) => throw StateError('$f'),
    );

    expect(result.rolled, Rarity.legendary);
    expect(result.isLegendary, isTrue);
    expect(player.state.forceNextLegendary, isFalse);
  });

  test(
    'a character missing from storage is a StorageFailure, no change',
    () async {
      // Havuzda var, ama karakterler kutusuna asla yazılmaz.
      final ghost = parseCharacter(loadCharacter(1)..['id'] = 424242)
          .getOrElse((f) => throw StateError('$f'));
      final r = PortalRepositoryImpl(
        apiData: apiData,
        player: player,
        collection: collection,
        pool: RarityPool.fromCharacters([ghost]),
        random: Random(1),
      );

      final result = await r.open();

      expect(result.getLeft().toNullable(), isA<StorageFailure>());
      expect(player.state.coins, 300);
      expect(collection.ownedIds, isEmpty);
    },
  );
}
