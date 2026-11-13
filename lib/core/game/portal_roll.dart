import 'dart:math';

import 'rarity.dart';

/// Result of one portal pick [GM §7].
final class PortalPick {
  const PortalPick({
    required this.rolled,
    required this.rarity,
    required this.characterId,
    required this.isDuplicate,
  });

  /// Rarity from the roll (or the demo override).
  final Rarity rolled;

  /// Rarity of the character actually given (lower after a step-down).
  final Rarity rarity;
  final int characterId;
  final bool isDuplicate;

  @override
  String toString() =>
      'PortalPick(rolled: ${rolled.name}, rarity: ${rarity.name}, '
      'id: $characterId, duplicate: $isDuplicate)';
}

/// Portal roll [GM §7, §7.1–§7.3]. Pure Dart; `Random` is always passed in.
abstract final class PortalRoll {
  /// Chance per rarity [GM §7].
  static const Map<Rarity, double> chances = {
    Rarity.common: 0.60,
    Rarity.rare: 0.28,
    Rarity.epic: 0.10,
    Rarity.legendary: 0.02,
  };

  /// Portals that never give a duplicate [GM §7.1].
  static const int guaranteedNewPortals = 3;

  /// Draws a rarity with [chances] (one `nextDouble`).
  static Rarity rollRarity(Random random) {
    final x = random.nextDouble();
    var edge = 0.0;
    for (final rarity in Rarity.values) {
      edge += chances[rarity]!;
      if (x < edge) return rarity;
    }
    return Rarity.common; // float rounding at 1.0
  }

  /// Picks the character for one portal.
  ///
  /// - [forceLegendary] (demo, [GM §7.2]) skips the rarity roll.
  /// - While [portalsOpened] < 3 only unowned characters are given, stepping
  ///   down a rarity when one is used up [GM §7.1, §7.3]; if the player owns
  ///   every character, a normal duplicate from the rolled rarity.
  /// - Later portals pick uniformly from the rolled rarity (duplicates
  ///   allowed). An empty rarity pool steps down, then up.
  static PortalPick pick({
    required Map<Rarity, List<int>> pool,
    required Set<int> owned,
    required int portalsOpened,
    required bool forceLegendary,
    required Random random,
  }) {
    final rolled = forceLegendary ? Rarity.legendary : rollRarity(random);

    if (portalsOpened < guaranteedNewPortals) {
      for (final rarity in _stepDown(rolled)) {
        final fresh = [
          for (final id in pool[rarity] ?? const <int>[])
            if (!owned.contains(id)) id,
        ];
        if (fresh.isNotEmpty) {
          return PortalPick(
            rolled: rolled,
            rarity: rarity,
            characterId: fresh[random.nextInt(fresh.length)],
            isDuplicate: false,
          );
        }
      }
    }

    final rarity = _firstNonEmpty(pool, rolled);
    final ids = pool[rarity]!;
    final id = ids[random.nextInt(ids.length)];
    return PortalPick(
      rolled: rolled,
      rarity: rarity,
      characterId: id,
      isDuplicate: owned.contains(id),
    );
  }

  /// [from], then each lower rarity (legendary → epic → rare → common).
  static Iterable<Rarity> _stepDown(Rarity from) =>
      Rarity.values.reversed.where((r) => r.index <= from.index);

  static Rarity _firstNonEmpty(Map<Rarity, List<int>> pool, Rarity from) {
    final order = [
      ..._stepDown(from),
      ...Rarity.values.where((r) => r.index > from.index),
    ];
    for (final r in order) {
      if ((pool[r] ?? const []).isNotEmpty) return r;
    }
    throw StateError('portal pool is empty');
  }
}
