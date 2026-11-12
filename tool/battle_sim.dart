// Battle balance simulation (plan T42). Pure Dart, real engine + AI.
//
//   dart run tool/battle_sim.dart                 # current GM 4 base values
//   dart run tool/battle_sim.dart --search        # also try other HP/ATK
//
// Teams are drawn from ids 1..826 with a type and status mix close to the
// API (types uniform over the six, status 55 % Alive / 35 % Dead / 10 %
// unknown). 1000 battles per scenario, seeds 0..999, AI plays both sides.
import 'dart:io';
import 'dart:math';

import 'package:portalcards/core/game/battle_engine.dart';
import 'package:portalcards/core/game/battle_model.dart';
import 'package:portalcards/core/game/card_stats.dart';
import 'package:portalcards/core/game/card_type.dart';
import 'package:portalcards/core/game/featured.dart';
import 'package:portalcards/core/game/passives.dart';
import 'package:portalcards/core/game/rarity.dart';

typedef Bases = ({int hp, int atk, int def, int spd});

const int battles = 1000;

BattleCard makeCard(int id, Rarity r, Random rnd, Bases b, {Signature? sig}) {
  final roll = rnd.nextDouble();
  final passive = roll < 0.55
      ? Passive.none
      : roll < 0.90
      ? Passive.zombie
      : Passive.uncertain;
  return BattleCard.fromStats(
    id: id,
    type: CardType.values[rnd.nextInt(CardType.values.length)],
    passive: passive,
    signature: sig,
    stats: CardStats.compute(
      id,
      r,
      hp: b.hp,
      atk: b.atk,
      def: b.def,
      spd: b.spd,
    ),
  );
}

List<BattleCard> team(List<Rarity> rs, Random rnd, Bases b) => [
  for (final r in rs) makeCard(1 + rnd.nextInt(826), r, rnd, b),
];

typedef Report = ({double turns, double draws, double playerWins});

Report run(List<Rarity> p, List<Rarity> e, Bases b, {Signature? featured}) {
  var turns = 0;
  var draws = 0;
  var wins = 0;
  for (var seed = 0; seed < battles; seed++) {
    final rnd = Random(seed);
    final pt = team(p, rnd, b);
    if (featured != null) {
      final f = pt[0];
      pt[0] = makeCard(f.id, p[0], Random(seed + 7), b, sig: featured);
    }
    var s = BattleEngine.start(pt, team(e, rnd, b));
    while (!s.over) {
      s = BattleEngine.aiTurn(s, rnd).state;
    }
    turns += s.turn;
    if (s.result == BattleResult.draw) draws++;
    if (s.result == BattleResult.victory) wins++;
  }
  return (
    turns: turns / battles,
    draws: draws / battles,
    playerWins: wins / battles,
  );
}

/// Average hits for one equal card to faint another (no crit/type).
double hitsToFaint(Rarity r, Bases b) {
  var total = 0.0;
  var n = 0;
  for (var a = 1; a <= 400; a++) {
    final x = CardStats.compute(
      a,
      r,
      hp: b.hp,
      atk: b.atk,
      def: b.def,
      spd: b.spd,
    );
    final y = CardStats.compute(
      a + 400,
      r,
      hp: b.hp,
      atk: b.atk,
      def: b.def,
      spd: b.spd,
    );
    final dmg = max(1, (x.atk * 50 / (50 + y.def)).round());
    total += (y.hp / dmg).ceil();
    n++;
  }
  return total / n;
}

const c = Rarity.common, r = Rarity.rare, e = Rarity.epic, l = Rarity.legendary;

void report(Bases b) {
  stdout.writeln('\nbase HP ${b.hp} ATK ${b.atk} DEF ${b.def} SPD ${b.spd}');
  for (final rar in Rarity.values) {
    stdout.writeln(
      '  hits to faint (equal ${rar.name}): ${hitsToFaint(rar, b).toStringAsFixed(2)}',
    );
  }
  final scenarios = <(String, List<Rarity>, List<Rarity>)>[
    ('equal common', [c, c, c], [c, c, c]),
    ('equal rare', [r, r, r], [r, r, r]),
    ('equal legendary', [l, l, l], [l, l, l]),
    ('rare vs common', [r, r, r], [c, c, c]),
    ('epic vs rare', [e, e, e], [r, r, r]),
    ('legendary vs common', [l, l, l], [c, c, c]),
    ('tier 0 (mixed deck vs 3 common)', [c, r, e], [c, c, c]),
    ('tier 2 (mixed deck vs C+R+R)', [c, r, e], [c, r, r]),
    ('tier 4 (mixed deck vs R+E+E)', [c, r, e], [r, e, e]),
  ];
  stdout.writeln(
    '  scenario                              turns  draws  player wins',
  );
  for (final (name, p, en) in scenarios) {
    final rep = run(p, en, b);
    stdout.writeln(
      '  ${name.padRight(36)} ${rep.turns.toStringAsFixed(1).padLeft(5)}'
      '  ${(rep.draws * 100).toStringAsFixed(1).padLeft(4)} %'
      '  ${(rep.playerWins * 100).toStringAsFixed(1).padLeft(5)} %',
    );
  }
  stdout.writeln('  featured vs same team (rare x3), player win %:');
  for (final sig in Signature.values) {
    final rep = run([r, r, r], [r, r, r], b, featured: sig);
    stdout.writeln(
      '    ${sig.name.padRight(16)} ${(rep.playerWins * 100).toStringAsFixed(1)} %',
    );
  }
}

void main(List<String> args) {
  const current = (
    hp: CardStats.baseHp,
    atk: CardStats.baseAtk,
    def: CardStats.baseDef,
    spd: CardStats.baseSpd,
  );
  report(current);
  if (!args.contains('--search')) return;

  stdout.writeln('\nsearch: equal common/rare/legendary turns and draws');
  for (final hp in [60, 70, 80, 90, 100]) {
    for (final atk in [20, 25, 30, 35, 40]) {
      final b = (
        hp: hp,
        atk: atk,
        def: CardStats.baseDef,
        spd: CardStats.baseSpd,
      );
      final eq = [
        run([c, c, c], [c, c, c], b),
        run([r, r, r], [r, r, r], b),
        run([l, l, l], [l, l, l], b),
      ];
      final turns = eq.map((x) => x.turns).reduce((a, b) => a + b) / 3;
      final draws = eq.map((x) => x.draws).reduce((a, b) => a + b) / 3;
      stdout.writeln(
        '  HP ${hp.toString().padLeft(3)} ATK ${atk.toString().padLeft(2)}'
        '  hits ${hitsToFaint(Rarity.rare, b).toStringAsFixed(2)}'
        '  turns ${turns.toStringAsFixed(1)}  draws ${(draws * 100).toStringAsFixed(1)} %',
      );
    }
  }
}
