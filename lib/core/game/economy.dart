import 'dart:math';

import 'rarity.dart';

/// Coin rules [GM §8] and the only way to change a balance (SPEC §3:
/// "Economy is the only writer of coins"). Pure: it returns a
/// [CoinTransaction]; the caller saves it and logs it.
abstract final class EconomyRules {
  /// Coins of a new player: three portals.
  static const int startingCoins = 300;

  /// Price of one portal [GM §7].
  static const int portalCost = 100;

  /// Hidden demo panel "+1000 coin" (SPEC D2).
  static const int demoBonus = 1000;

  static const int defeatCoins = 25;
  static const int drawCoins = 50;
  static const int victoryBase = 100;
  static const int victoryPerTier = 25;
  static const int albumBase = 150;
  static const int albumPerMember = 10;
  static const int albumMax = 500;
}

/// Why coins changed (logged with every change).
enum CoinReason { portal, duplicate, victory, defeat, draw, album, demo }

/// One applied change. [after] is never below 0.
final class CoinTransaction {
  const CoinTransaction({
    required this.reason,
    required this.delta,
    required this.before,
    required this.after,
  });

  final CoinReason reason;
  final int delta;
  final int before;
  final int after;

  @override
  String toString() => 'coins ${reason.name} $delta: $before -> $after';
}

abstract final class Economy {
  /// Coins paid for a duplicate card (before merge exists).
  static int duplicateCoins(Rarity rarity) => switch (rarity) {
    Rarity.common => 20,
    Rarity.rare => 40,
    Rarity.epic => 80,
    Rarity.legendary => 200,
  };

  static int victoryCoins(int tier) =>
      EconomyRules.victoryBase + EconomyRules.victoryPerTier * tier;

  static int albumCoins(int members) => min(
    EconomyRules.albumMax,
    EconomyRules.albumBase + EconomyRules.albumPerMember * members,
  );

  /// Adds [amount] (≥ 0) for [reason].
  static CoinTransaction earn(int balance, int amount, CoinReason reason) {
    assert(amount >= 0, 'use spend() to take coins');
    return CoinTransaction(
      reason: reason,
      delta: amount,
      before: balance,
      after: balance + amount,
    );
  }

  /// Takes [amount] if the balance allows it; null if not (nothing changes).
  static CoinTransaction? spend(int balance, int amount, CoinReason reason) {
    if (amount < 0 || balance < amount) return null;
    return CoinTransaction(
      reason: reason,
      delta: -amount,
      before: balance,
      after: balance - amount,
    );
  }

  static bool canAffordPortal(int balance) =>
      balance >= EconomyRules.portalCost;
}
