import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/cards/game_card_data.dart';
import '../../../core/errors/failures.dart';
import '../../../core/game/battle_model.dart';

/// What a finished battle paid out ([GM §8]).
final class BattleReward extends Equatable {
  const BattleReward({
    required this.result,
    required this.coins,
    required this.coinsAfter,
    required this.wins,
    required this.tierBefore,
    required this.tierAfter,
  });

  final BattleResult result;
  final int coins;
  final int coinsAfter;
  final int wins;
  final int tierBefore;
  final int tierAfter;

  bool get tierUp => tierAfter > tierBefore;

  @override
  List<Object?> get props => [
    result,
    coins,
    coinsAfter,
    wins,
    tierBefore,
    tierAfter,
  ];
}

abstract interface class BattleRepository {
  /// The player's deck as cards (empty slots skipped).
  List<GameCardData> deck();

  /// Fires whenever the player's stored data (deck, coins, wins) changes.
  Stream<void> get changes;

  int get wins;
  int get tier;

  /// A new opponent team for the current tier [GM §6].
  List<GameCardData> opponents(Random random);

  /// Credits the reward once per [battleId] (a second call returns the same
  /// reward without paying again) and updates `wins`. Leaving mid-battle
  /// is a defeat (decision Q4).
  Future<Either<Failure, BattleReward>> finish(
    String battleId,
    BattleResult result,
  );
}
