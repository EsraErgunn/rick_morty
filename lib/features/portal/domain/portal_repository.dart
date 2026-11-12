import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/cards/game_card_data.dart';
import '../../../core/errors/failures.dart';
import '../../../core/game/rarity.dart';

/// What one portal gave. Already saved when the caller gets it
/// (write-before-animate, SPEC §2.3 AC8).
final class PortalResult extends Equatable {
  const PortalResult({
    required this.card,
    required this.rolled,
    required this.isDuplicate,
    required this.duplicateCoins,
    required this.coinsBefore,
    required this.coinsAfter,
  });

  final GameCardData card;

  /// Rarity from the roll; differs from `card.rarity` after a step-down.
  final Rarity rolled;
  final bool isDuplicate;

  /// Coins paid back for a duplicate (0 for a new card).
  final int duplicateCoins;
  final int coinsBefore;
  final int coinsAfter;

  bool get isLegendary => card.rarity == Rarity.legendary;

  @override
  List<Object?> get props => [
    card,
    rolled,
    isDuplicate,
    duplicateCoins,
    coinsBefore,
    coinsAfter,
  ];
}

abstract interface class PortalRepository {
  /// Current coins (for the counter and the "not enough coins" check).
  int get coins;

  /// False until the first portal opened (shake hint, SPEC D4).
  bool get shakeHintSeen;

  /// Spends the portal cost, rolls, saves the card (or the duplicate
  /// coins) and the player state, then returns the result.
  /// [NotEnoughCoinsFailure] changes nothing.
  Future<Either<Failure, PortalResult>> open();
}
