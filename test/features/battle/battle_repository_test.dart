import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/cards/rarity_pool.dart';
import 'package:portalcards/core/game/battle_model.dart';
import 'package:portalcards/core/storage/api_data_store.dart';
import 'package:portalcards/core/storage/player_store.dart';
import 'package:portalcards/features/battle/data/battle_repository_impl.dart';
import 'package:portalcards/features/sync/data/mappers.dart';

import '../../core/storage/hive_test_helper.dart';
import '../../fixtures/fixtures.dart';

void main() {
  useTempHive();

  late PlayerStore player;
  late BattleRepositoryImpl repo;

  setUp(() async {
    final api = await ApiDataStore.open();
    final chars = [
      for (final id in characterFixtures.keys)
        parseCharacter(loadCharacter(id))
            .getOrElse((f) => throw StateError('$f')),
    ];
    await api.putCharacters(chars);
    player = await PlayerStore.open();
    repo = BattleRepositoryImpl(
      apiData: api,
      player: player,
      pool: RarityPool.fromCharacters(chars),
    );
  });

  test('deck cards in order; opponents are three cards', () async {
    await player.update((s) => s.copyWith(deck: [71, 1, 23]));
    expect(repo.deck().map((c) => c.id), [71, 1, 23]);
    expect(repo.opponents(Random(1)), hasLength(3));
  });

  test('victory pays 100 + 25 x tier and counts a win', () async {
    final r = (await repo.finish(
      'b1',
      BattleResult.victory,
    )).getOrElse((f) => throw StateError('$f'));
    expect(r.coins, 100);
    expect(player.state.coins, 400);
    expect(player.state.wins, 1);
  });

  test('defeat 25, draw 50, no win', () async {
    await repo.finish('b1', BattleResult.defeat);
    await repo.finish('b2', BattleResult.draw);
    expect(player.state.coins, 375);
    expect(player.state.wins, 0);
  });

  test('the same battle is paid only once', () async {
    await repo.finish('b1', BattleResult.victory);
    final again = await repo.finish('b1', BattleResult.victory);
    expect(again.isRight(), isTrue);
    expect(player.state.coins, 400);
    expect(player.state.wins, 1);
  });

  test('the third win raises the tier', () async {
    await player.update((s) => s.copyWith(wins: 2));
    final r = (await repo.finish(
      'b9',
      BattleResult.victory,
    )).getOrElse((f) => throw StateError('$f'));
    expect(r.tierBefore, 0);
    expect(r.tierAfter, 1);
    expect(r.tierUp, isTrue);
  });
}
