import 'battle_model.dart';
import 'card_type.dart';

/// Simple, readable AI [GM §6]: no randomness, no hidden information.
abstract final class BattleAi {
  /// (attacker index, target index) for [side].
  /// 1. A super-effective pair → the one with the highest expected damage.
  /// 2. Else the highest-ATK card attacks the lowest-HP enemy.
  /// Ties: the first card in team order (deterministic).
  static (int, int) choose(BattleState state, Side side) {
    final own = state.cards(side);
    final foe = state.cards(side.other);
    final ownAlive = [
      for (var i = 0; i < own.length; i++)
        if (own[i].alive) i,
    ];
    final foeAlive = [
      for (var i = 0; i < foe.length; i++)
        if (foe[i].alive) i,
    ];

    (int, int)? best;
    var bestDamage = -1.0;
    for (final a in ownAlive) {
      for (final t in foeAlive) {
        if (Effectiveness.of(own[a].type, foe[t].type) !=
            Effectiveness.superEffective) {
          continue;
        }
        final expected =
            own[a].atk *
            Effectiveness.superEffective.multiplier *
            50 /
            (50 + foe[t].def);
        if (expected > bestDamage) {
          best = (a, t);
          bestDamage = expected;
        }
      }
    }
    if (best != null) return best;

    var attacker = ownAlive.first;
    for (final a in ownAlive.skip(1)) {
      if (own[a].atk > own[attacker].atk) attacker = a;
    }
    var target = foeAlive.first;
    for (final t in foeAlive.skip(1)) {
      if (foe[t].hp < foe[target].hp) target = t;
    }
    return (attacker, target);
  }
}
