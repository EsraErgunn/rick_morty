import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/cards/game_card_data.dart';
import '../../../core/errors/failures.dart';
import '../../../core/game/battle_model.dart';

/// Biten bir savaşın ödediği ([GM §8]).
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

/// Savaş ekranının veri kaynağı: deste, rakip üretimi ve ödüller.
abstract interface class BattleRepository {
  /// Oyuncunun destesi kart olarak (boş slotlar atlanır).
  List<GameCardData> deck();

  /// Oyuncunun kayıtlı verileri (deste, coin, galibiyet) her değiştiğinde tetiklenir.
  Stream<void> get changes;

  int get wins;
  int get tier;

  /// Mevcut kademe için yeni bir rakip takım [GM §6].
  List<GameCardData> opponents(Random random);

  /// Ödülü [battleId] başına bir kez öder (ikinci çağrı tekrar ödemeden aynı
  /// ödülü döndürür) ve `wins` değerini günceller. Savaşın ortasında çıkmak
  /// yenilgi sayılır (karar S4).
  Future<Either<Failure, BattleReward>> finish(
    String battleId,
    BattleResult result,
  );
}
