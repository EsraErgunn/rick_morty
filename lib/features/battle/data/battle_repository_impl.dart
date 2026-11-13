import 'dart:math';

import 'package:fpdart/fpdart.dart';

import '../../../core/cards/card_factory.dart';
import '../../../core/cards/game_card_data.dart';
import '../../../core/cards/rarity_pool.dart';
import '../../../core/errors/failures.dart';
import '../../../core/game/battle_model.dart';
import '../../../core/game/economy.dart';
import '../../../core/game/opponents.dart';
import '../../../core/game/rarity.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/api_data_store.dart';
import '../../../core/storage/player_store.dart';
import '../domain/battle_repository.dart';

/// [BattleRepository]'nin Hive depolarıyla çalışan uygulaması.
class BattleRepositoryImpl implements BattleRepository {
  BattleRepositoryImpl({
    required this._apiData,
    required this._player,
    required this._pool,
  });

  final ApiDataStore _apiData;
  final PlayerStore _player;
  final RarityPool _pool;
  BattleReward? _lastReward;

  GameCardData? _card(int id) => switch (_apiData.character(id)) {
    final c? => CardFactory.fromCharacter(c),
    null => null,
  };

  @override
  Stream<void> get changes => _player.changes;

  @override
  List<GameCardData> deck() => [
    for (final id in _player.state.deck) ?_card(id),
  ];

  @override
  int get wins => _player.state.wins;

  @override
  int get tier => Opponents.tierFor(wins);

  @override
  List<GameCardData> opponents(Random random) => [
    for (final id in Opponents.team(
      pool: {for (final r in Rarity.values) r: _pool.ids(r)},
      wins: wins,
      random: random,
    ))
      ?_card(id),
  ];

  @override
  Future<Either<Failure, BattleReward>> finish(
    String battleId,
    BattleResult result,
  ) async {
    final state = _player.state;
    if (state.lastBattleId == battleId && _lastReward != null) {
      return right(_lastReward!);
    }
    final tierBefore = Opponents.tierFor(state.wins);
    final (amount, reason) = switch (result) {
      BattleResult.victory => (
        Economy.victoryCoins(tierBefore),
        CoinReason.victory,
      ),
      BattleResult.defeat => (EconomyRules.defeatCoins, CoinReason.defeat),
      BattleResult.draw => (EconomyRules.drawCoins, CoinReason.draw),
    };
    final t = Economy.earn(state.coins, amount, reason);
    final wins = state.wins + (result == BattleResult.victory ? 1 : 0);
    try {
      await _player.update(
        (s) => s.copyWith(coins: t.after, wins: wins, lastBattleId: battleId),
      );
    } on Object catch (e) {
      return left(StorageFailure(e.runtimeType.toString()));
    }
    AppLogger.info('$t');
    return right(
      _lastReward = BattleReward(
        result: result,
        coins: amount,
        coinsAfter: t.after,
        wins: wins,
        tierBefore: tierBefore,
        tierAfter: Opponents.tierFor(wins),
      ),
    );
  }
}
