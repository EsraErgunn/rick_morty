import 'battle_model.dart';
import 'card_type.dart';

/// Basit, okunabilir yapay zekâ [GM §6]: rastgelelik yok, gizli bilgi yok.
abstract final class BattleAi {
  /// [side] için (saldıran indeksi, hedef indeksi).
  /// 1. Süper etkili bir eşleşme → beklenen hasarı en yüksek olan.
  /// 2. Yoksa ATK'sı en yüksek kart HP'si en düşük rakibe saldırır.
  /// Eşitlik: takım sırasındaki ilk kart (deterministik).
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
