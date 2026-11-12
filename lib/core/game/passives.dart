import 'dart:math';

/// Passive ability from the API `status` [GM §5].
/// UI names: zombie = "Zombi", uncertain = "Belirsiz" (from l10n).
enum Passive {
  /// Alive: no passive.
  none,

  /// Dead: once per battle, revives at 30% max HP when HP drops to 0.
  zombie,

  /// unknown: each attack deals ×1.2 or ×0.8 damage, 50/50.
  uncertain;

  /// Maps an API status string. Anything other than Dead / unknown is
  /// treated as Alive.
  static Passive fromStatus(String status) =>
      switch (status.trim().toLowerCase()) {
        'dead' => zombie,
        'unknown' => uncertain,
        _ => none,
      };
}

/// Formulas for the passives. Randomness is always passed in.
abstract final class Passives {
  static const double zombieReviveFraction = 0.30;
  static const double uncertainChance = 0.5;
  static const double uncertainHigh = 1.2;
  static const double uncertainLow = 0.8;

  /// HP a Zombi card comes back with: 30% of [maxHp], rounded, at least 1.
  static int zombieReviveHp(int maxHp) =>
      max(1, (maxHp * zombieReviveFraction).round());

  /// Damage multiplier for one attack by a card with [passive].
  /// Only [Passive.uncertain] uses [random]; the others return 1.0 without
  /// drawing from it, so they do not shift the battle's random sequence.
  static double attackMultiplier(Passive passive, Random random) =>
      switch (passive) {
        Passive.uncertain =>
          random.nextDouble() < uncertainChance ? uncertainHigh : uncertainLow,
        Passive.none || Passive.zombie => 1,
      };
}
