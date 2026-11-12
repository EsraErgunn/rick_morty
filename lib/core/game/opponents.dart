import 'dart:math';

import 'rarity.dart';

/// Opponent teams by difficulty tier [GM §6].
abstract final class Opponents {
  static const int winsPerTier = 3;
  static const int maxTier = 4;
  static const int teamSize = 3;

  /// Tier 4: the third card is legendary with this chance, else epic.
  static const double tier4LegendaryChance = 0.10;

  static int tierFor(int wins) => min(maxTier, wins ~/ winsPerTier);

  /// Rarity of each opponent slot. Uses [random] only for tier 4's slot 3.
  static List<Rarity> rarities(int tier, Random random) => switch (tier) {
    0 => const [Rarity.common, Rarity.common, Rarity.common],
    1 => const [Rarity.common, Rarity.common, Rarity.rare],
    2 => const [Rarity.common, Rarity.rare, Rarity.rare],
    3 => const [Rarity.rare, Rarity.rare, Rarity.epic],
    _ => [
      Rarity.rare,
      Rarity.epic,
      random.nextDouble() < tier4LegendaryChance
          ? Rarity.legendary
          : Rarity.epic,
    ],
  };

  /// Three different character ids for [wins]; an empty rarity steps down,
  /// then up (like [GM §7.3]).
  static List<int> team({
    required Map<Rarity, List<int>> pool,
    required int wins,
    required Random random,
  }) {
    final picked = <int>[];
    for (final rarity in rarities(tierFor(wins), random)) {
      final order = [
        ...Rarity.values.reversed.where((r) => r.index <= rarity.index),
        ...Rarity.values.where((r) => r.index > rarity.index),
      ];
      for (final r in order) {
        final free = [
          for (final id in pool[r] ?? const <int>[])
            if (!picked.contains(id)) id,
        ];
        if (free.isNotEmpty) {
          picked.add(free[random.nextInt(free.length)]);
          break;
        }
      }
    }
    return picked;
  }
}
