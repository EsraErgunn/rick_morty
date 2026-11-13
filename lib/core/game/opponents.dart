import 'dart:math';

import 'rarity.dart';

/// Zorluk kademesine göre rakip takımlar [GM §6].
abstract final class Opponents {
  static const int winsPerTier = 3;
  static const int maxTier = 4;
  static const int teamSize = 3;

  /// Kademe 4: üçüncü kart bu şansla efsanevi, değilse epik.
  static const double tier4LegendaryChance = 0.10;

  static int tierFor(int wins) => min(maxTier, wins ~/ winsPerTier);

  /// Her rakip slotunun nadirliği. [random] yalnızca kademe 4'ün 3. slotu için kullanılır.
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

  /// [wins] için üç farklı karakter id'si; boş bir nadirlik önce aşağı,
  /// sonra yukarı kayar ([GM §7.3] gibi).
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
