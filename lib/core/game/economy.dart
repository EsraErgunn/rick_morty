import 'dart:math';

import 'rarity.dart';

/// Coin kuralları [GM §8] ve bakiyeyi değiştirmenin tek yolu (SPEC §3:
/// "Coin'leri yalnızca Economy yazar"). Saf: bir
/// [CoinTransaction] döndürür; çağıran onu kaydeder ve loglar.
abstract final class EconomyRules {
  /// Yeni oyuncunun coin'i: üç portal.
  static const int startingCoins = 300;

  /// Bir portalın fiyatı [GM §7].
  static const int portalCost = 100;

  /// Gizli demo paneli "+1000 coin" (SPEC D2).
  static const int demoBonus = 1000;

  static const int defeatCoins = 25;
  static const int drawCoins = 50;
  static const int victoryBase = 100;
  static const int victoryPerTier = 25;
  static const int albumBase = 150;
  static const int albumPerMember = 10;
  static const int albumMax = 500;
}

/// Coin'lerin neden değiştiği (her değişiklikle loglanır).
enum CoinReason { portal, duplicate, victory, defeat, draw, album, demo }

/// Uygulanmış tek bir değişiklik. [after] asla 0'ın altına düşmez.
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

/// Tüm coin değişikliklerini hesaplayan saf sınıf [GM §8].
abstract final class Economy {
  /// Tekrar gelen bir kart için ödenen coin (birleştirme özelliği gelmeden önce).
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

  /// [reason] için [amount] (≥ 0) ekler.
  static CoinTransaction earn(int balance, int amount, CoinReason reason) {
    assert(amount >= 0, 'use spend() to take coins');
    return CoinTransaction(
      reason: reason,
      delta: amount,
      before: balance,
      after: balance + amount,
    );
  }

  /// Bakiye yetiyorsa [amount] düşer; yetmiyorsa null (hiçbir şey değişmez).
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
