/// Coin rules [GM §8]. The full `Economy` class (the only writer of coins,
/// with reasons) comes with the portal in Week 2; this file already holds
/// the constants so they are defined once.
abstract final class EconomyRules {
  /// Coins of a new player: three portals.
  static const int startingCoins = 300;

  /// Price of one portal [GM §7].
  static const int portalCost = 100;
}
