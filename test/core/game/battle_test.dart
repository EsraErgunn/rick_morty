import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/core/game/battle_ai.dart';
import 'package:portalcards/core/game/battle_engine.dart';
import 'package:portalcards/core/game/battle_model.dart';
import 'package:portalcards/core/game/card_type.dart';
import 'package:portalcards/core/game/featured.dart';
import 'package:portalcards/core/game/opponents.dart';
import 'package:portalcards/core/game/passives.dart';
import 'package:portalcards/core/game/rarity.dart';

BattleCard card(
  int id, {
  CardType type = CardType.neutral,
  Passive passive = Passive.none,
  Signature? signature,
  int hp = 100,
  int atk = 20,
  int def = 12,
  int spd = 10,
}) => BattleCard(
  id: id,
  type: type,
  passive: passive,
  signature: signature,
  maxHp: hp,
  atk: atk,
  def: def,
  spd: spd,
  hp: hp,
);

/// Random with fixed doubles (for exact crit/dodge/Belirsiz control).
class ScriptedRandom implements Random {
  ScriptedRandom(this.doubles);

  final List<double> doubles;
  var _i = 0;

  @override
  double nextDouble() => doubles[_i++ % doubles.length];

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

List<BattleEvent> events(BattleStep step) => step.events;

BattleStep player(BattleState s, int a, int t, Random r) =>
    BattleEngine.playerTurn(
      s,
      a,
      t,
      r,
    ).getOrElse((f) => throw StateError('$f'));

void main() {
  final noCrit = ScriptedRandom([0.9]);

  group('start', () {
    test('faster side starts; tie → player', () {
      expect(
        BattleEngine.start([card(1, spd: 9)], [card(2, spd: 10)]).active,
        Side.enemy,
      );
      expect(
        BattleEngine.start([card(1, spd: 10)], [card(2, spd: 10)]).active,
        Side.player,
      );
    });

    test('a Beast makes its side start (speed +∞ on turn 1)', () {
      final s = BattleEngine.start(
        [card(1, type: CardType.beast, spd: 1)],
        [card(2, spd: 99)],
      );
      expect(s.active, Side.player);
    });
  });

  group('damage', () {
    test('base: round(ATK × 50 / (50 + DEF))', () {
      final s = BattleEngine.start([card(1, atk: 33)], [card(2, def: 13)]);
      final d = events(player(s, 0, 0, noCrit)).whereType<Damaged>().single;
      expect(d.amount, (33 * 50 / 63).round()); // 26
      expect(d.isCrit, isFalse);
      expect(d.effectiveness, Effectiveness.normal);
    });

    test('Human attacking Robot is super effective (×1.5)', () {
      final s = BattleEngine.start(
        [card(1, type: CardType.human)],
        [card(2, type: CardType.robot)],
      );
      final d = events(player(s, 0, 0, noCrit)).whereType<Damaged>().single;
      expect(d.effectiveness, Effectiveness.superEffective);
      expect(d.amount, (20 * 1.5 * 50 / 62).round());
    });

    test('crit ×1.5; Rick (Dahi) crits at 20 % and shows DAHİ', () {
      final s = BattleEngine.start(
        [card(1, signature: Signature.genius)],
        [card(2)],
      );
      final d = events(player(s, 0, 0, ScriptedRandom([0.15])))
          .whereType<Damaged>()
          .single;
      expect(d.isCrit, isTrue);
      expect(d.signature, Signature.genius);
      expect(d.amount, (20 * 1.5 * 50 / 62).round());

      final plain = BattleEngine.start([card(1)], [card(2)]);
      expect(
        events(player(plain, 0, 0, ScriptedRandom([0.15])))
            .whereType<Damaged>()
            .single
            .isCrit,
        isFalse,
      );
    });

    test('crit rate over 10,000 seeded hits: 10 % normal, 20 % Rick', () {
      double rate(Signature? sig) {
        final r = Random(11);
        var crits = 0;
        for (var i = 0; i < 10000; i++) {
          final s = BattleEngine.start(
            [card(1, signature: sig)],
            [card(2, hp: 100000)],
          );
          if (events(player(s, 0, 0, r)).whereType<Damaged>().single.isCrit) {
            crits++;
          }
        }
        return crits / 10000;
      }

      expect(rate(null), closeTo(0.10, 0.02));
      expect(rate(Signature.genius), closeTo(0.20, 0.02));
    });

    test('minimum damage is 1', () {
      final s = BattleEngine.start([card(1, atk: 1)], [card(2, def: 500)]);
      expect(
        events(player(s, 0, 0, noCrit)).whereType<Damaged>().single.amount,
        1,
      );
    });
  });

  group('traits and passives', () {
    test('Myth dodges (10 %): no damage event', () {
      final s = BattleEngine.start([card(1)], [card(2, type: CardType.myth)]);
      final e = events(player(s, 0, 0, ScriptedRandom([0.05])));
      expect(e.whereType<Dodged>(), hasLength(1));
      expect(e.whereType<Damaged>(), isEmpty);
    });

    test('Zombi revives once at 30 % max HP', () {
      final s = BattleEngine.start(
        [card(1, atk: 500)],
        [card(2, passive: Passive.zombie, hp: 100), card(3)],
      );
      final step = player(s, 0, 0, noCrit);
      expect(step.events.whereType<Fainted>(), hasLength(1));
      expect(step.events.whereType<Revived>().single.hp, 30);
      expect(step.state.enemy[0].hp, 30);

      final again = player(
        step.state.copyWith(active: Side.player),
        0,
        0,
        noCrit,
      );
      expect(again.events.whereType<Revived>(), isEmpty);
      expect(again.state.enemy[0].alive, isFalse);
    });

    test('Belirsiz: ×1.2 or ×0.8', () {
      final s = BattleEngine.start(
        [card(1, passive: Passive.uncertain, atk: 50)],
        [card(2, def: 0, hp: 1000)],
      );
      final high = events(player(s, 0, 0, ScriptedRandom([0.9, 0.1])))
          .whereType<Damaged>()
          .single;
      final low = events(player(s, 0, 0, ScriptedRandom([0.9, 0.9])))
          .whereType<Damaged>()
          .single;
      expect(high.amount, 60);
      expect(low.amount, 40);
    });
  });

  group('signatures [GM 12.2]', () {
    test('Pickle Rick: first attack received ×0.5, only once', () {
      var s = BattleEngine.start(
        [card(1, atk: 62)],
        [card(2, def: 12, hp: 1000, signature: Signature.pickleArmor)],
      );
      final first = player(s, 0, 0, noCrit);
      expect(first.events.whereType<Damaged>().single.amount, 25);
      expect(
        first.events.whereType<SignatureTriggered>().single.signature,
        Signature.pickleArmor,
      );
      s = first.state.copyWith(active: Side.player);
      expect(
        events(player(s, 0, 0, noCrit)).whereType<Damaged>().single.amount,
        50,
      );
    });

    test('a dodged attack does not use the pickle armor (Q3)', () {
      final s = BattleEngine.start(
        [card(1)],
        [card(2, type: CardType.myth, signature: Signature.pickleArmor)],
      );
      final step = player(s, 0, 0, ScriptedRandom([0.01]));
      expect(step.state.enemy[0].signatureUsed, isFalse);
    });

    test('Morty: at ≤ 30 % HP his next attack is ×1.5 (once)', () {
      final s = BattleEngine.start(
        [card(1, atk: 75, def: 0)],
        [card(2, hp: 100, def: 0, signature: Signature.awJeez, atk: 20)],
      );
      final hit = player(s, 0, 0, noCrit); // 100 → 25
      expect(
        hit.events.whereType<SignatureTriggered>().single.signature,
        Signature.awJeez,
      );
      final counter = BattleEngine.aiTurn(hit.state, noCrit);
      expect(counter.events.whereType<Damaged>().single.amount, 30);
    });

    test('Mr. Meeseeks: a KO heals 20 % of max HP (once)', () {
      final s = BattleEngine.start(
        [
          card(
            1,
            hp: 100,
            atk: 500,
            signature: Signature.missionComplete,
          ).copyWith(hp: 50),
        ],
        [card(2), card(3)],
      );
      final step = player(s, 0, 0, noCrit);
      expect(step.events.whereType<Healed>().single.hpAfter, 70);
      expect(step.state.player[0].signatureUsed, isTrue);
    });

    test('Summer: an ally fainting gives ATK ×1.2 for the rest', () {
      final s = BattleEngine.start(
        [card(1, atk: 500)],
        [card(2), card(3, signature: Signature.teamSpirit)],
      );
      final step = player(s, 0, 0, noCrit);
      expect(step.state.enemy[1].teamSpirit, isTrue);
      final back = BattleEngine.aiTurn(step.state, noCrit);
      expect(
        back.events.whereType<Damaged>().single.amount,
        (20 * 1.2 * 50 / 62).round(),
      );
    });
  });

  group('rules', () {
    test('invalid moves are rejected', () {
      final s = BattleEngine.start([card(1)], [card(2, spd: 99)]);
      expect(
        BattleEngine.playerTurn(s, 0, 0, noCrit).getLeft().toNullable(),
        isA<InvalidMoveFailure>(),
      );
      final mine = BattleEngine.start([card(1, spd: 99)], [card(2)]);
      expect(BattleEngine.playerTurn(mine, 0, 5, noCrit).isLeft(), isTrue);
    });

    test('victory when every enemy faints; event order', () {
      final s = BattleEngine.start([card(1, atk: 999)], [card(2)]);
      final e = events(player(s, 0, 0, noCrit));
      expect(e.map((x) => x.runtimeType.toString()), [
        'TurnStarted',
        'Attacked',
        'Damaged',
        'Fainted',
        'TurnEnded',
        'BattleEnded',
      ]);
      expect((e.last as BattleEnded).result, BattleResult.victory);
    });

    test('draw after 40 turns', () {
      var s = BattleEngine.start(
        [card(1, atk: 1, hp: 9999)],
        [card(2, atk: 1, hp: 9999)],
      );
      final r = Random(1);
      while (!s.over) {
        s = BattleEngine.aiTurn(s, r).state;
      }
      expect(s.result, BattleResult.draw);
      expect(s.turn, BattleEngine.maxTurns);
    });

    test('same seed + same choices → same event list (AC7)', () {
      List<BattleEvent> run() {
        final r = Random(42);
        var s = BattleEngine.start(
          [card(1, passive: Passive.uncertain), card(2, type: CardType.human)],
          [card(3, type: CardType.myth), card(4, passive: Passive.zombie)],
        );
        final all = <BattleEvent>[];
        while (!s.over) {
          final step = BattleEngine.aiTurn(s, r);
          all.addAll(step.events);
          s = step.state;
        }
        return all;
      }

      expect(run(), run());
    });
  });

  group('AI', () {
    test('takes a super-effective pair first', () {
      final s = BattleState(
        player: [
          card(10, type: CardType.alien),
          card(11, type: CardType.robot, hp: 5),
        ],
        enemy: [
          card(20, type: CardType.human, atk: 10),
          card(21, type: CardType.robot, atk: 30),
        ],
        active: Side.enemy,
      );
      expect(BattleAi.choose(s, Side.enemy), (1, 0)); // Robot → Alien
    });

    test('otherwise highest ATK on the lowest HP', () {
      final s = BattleState(
        player: [card(10, hp: 50), card(11, hp: 20)],
        enemy: [card(20, atk: 10), card(21, atk: 30)],
        active: Side.enemy,
      );
      expect(BattleAi.choose(s, Side.enemy), (1, 1));
    });
  });

  group('opponents [GM 6]', () {
    final pool = {
      Rarity.common: [for (var i = 0; i < 50; i++) 1000 + i],
      Rarity.rare: [for (var i = 0; i < 20; i++) 2000 + i],
      Rarity.epic: [for (var i = 0; i < 10; i++) 3000 + i],
      Rarity.legendary: [1, 2, 3],
    };

    test('tier = wins ÷ 3, max 4', () {
      expect([0, 2, 3, 8, 12, 99].map(Opponents.tierFor), [0, 0, 1, 2, 4, 4]);
    });

    test('rarity mix per tier, three different cards', () {
      Rarity of(int id) =>
          pool.entries.firstWhere((e) => e.value.contains(id)).key;
      for (final (wins, expected) in [
        (0, [Rarity.common, Rarity.common, Rarity.common]),
        (3, [Rarity.common, Rarity.common, Rarity.rare]),
        (6, [Rarity.common, Rarity.rare, Rarity.rare]),
        (9, [Rarity.rare, Rarity.rare, Rarity.epic]),
      ]) {
        final team = Opponents.team(
          pool: pool,
          wins: wins,
          random: Random(wins),
        );
        expect(team.toSet(), hasLength(3));
        expect(team.map(of), expected);
      }
    });

    test('tier 4 third slot is legendary 10 % (±2 %) over 10,000 teams', () {
      final r = Random(5);
      var legendary = 0;
      for (var i = 0; i < 10000; i++) {
        if (Opponents.rarities(4, r)[2] == Rarity.legendary) legendary++;
      }
      expect(legendary / 10000, closeTo(0.10, 0.02));
    });
  });
}
