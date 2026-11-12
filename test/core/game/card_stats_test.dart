import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/game/card_stats.dart';
import 'package:portalcards/core/game/rarity.dart';

import '../../fixtures/fixtures.dart';

CardStats _fromFixture(int id) {
  final json = loadCharacter(id);
  final rarity = Rarity.fromEpisodeCount(
    (json['episode'] as List<dynamic>).length,
  );
  return CardStats.forCharacter(json['id'] as int, rarity);
}

void main() {
  group('hash and roll', () {
    test('hash keeps the low 32 bits of n * 2654435761', () {
      expect(CardStats.hash(0), 0);
      expect(CardStats.hash(1), 2654435761);
      expect(CardStats.hash(2), (2 * 2654435761) & 0xFFFFFFFF);
    });

    test('mix is murmur3 fmix32 (reference value)', () {
      expect(CardStats.mix(0), 0);
      expect(CardStats.mix(CardStats.hash(31)), 2359591629);
    });

    test('statRoll(1, 0) is fmix32(hash(31)) / 0xFFFFFFFF', () {
      expect(CardStats.statRoll(1, 0), 2359591629 / 0xFFFFFFFF);
    });

    test(
      'stat rolls of one card are independent (|corr| < 0.15 over 1-826)',
      () {
        double corr(int a, int b) {
          final xs = [
            for (var id = 1; id <= 826; id++) CardStats.statRoll(id, a),
          ];
          final ys = [
            for (var id = 1; id <= 826; id++) CardStats.statRoll(id, b),
          ];
          final mx = xs.reduce((p, q) => p + q) / xs.length;
          final my = ys.reduce((p, q) => p + q) / ys.length;
          var sxy = 0.0, sxx = 0.0, syy = 0.0;
          for (var i = 0; i < xs.length; i++) {
            sxy += (xs[i] - mx) * (ys[i] - my);
            sxx += (xs[i] - mx) * (xs[i] - mx);
            syy += (ys[i] - my) * (ys[i] - my);
          }
          return sxy / math.sqrt(sxx * syy);
        }

        for (var a = 0; a < 4; a++) {
          for (var b = a + 1; b < 4; b++) {
            expect(corr(a, b).abs(), lessThan(0.15), reason: 'stats $a and $b');
          }
        }
      },
    );

    test('rolls are in [0, 1] for every id and stat index', () {
      for (var id = 1; id <= 826; id++) {
        for (var k = 0; k < 4; k++) {
          expect(CardStats.statRoll(id, k), inInclusiveRange(0, 1));
        }
      }
    });
  });

  group('hand-computed values (independent calculation, GM 4)', () {
    test('Rick (id 1, legendary) is HP 152, ATK 33, DEF 17, SPD 17', () {
      expect(
        _fromFixture(1),
        const CardStats(hp: 152, atk: 33, def: 17, spd: 17),
      );
    });

    test('Morty (id 2, legendary) is HP 140, ATK 26, DEF 16, SPD 15', () {
      expect(
        _fromFixture(2),
        const CardStats(hp: 140, atk: 26, def: 16, spd: 15),
      );
    });

    test(
      'Conroy (id 71, common, 1 episode) is HP 85, ATK 18, DEF 13, SPD 11',
      () {
        expect(
          _fromFixture(71),
          const CardStats(hp: 85, atk: 18, def: 13, spd: 11),
        );
      },
    );

    test('Arcade Alien (id 23, epic) is HP 126, ATK 28, DEF 14, SPD 13', () {
      expect(
        _fromFixture(23),
        const CardStats(hp: 126, atk: 28, def: 14, spd: 13),
      );
    });

    test('Cyclops Rick (id 86, rare) is HP 119, ATK 21, DEF 14, SPD 13', () {
      expect(
        _fromFixture(86),
        const CardStats(hp: 119, atk: 21, def: 14, spd: 13),
      );
    });
  });

  test('same id and rarity give identical stats every time', () {
    for (var id = 1; id <= 826; id++) {
      for (final rarity in Rarity.values) {
        expect(
          CardStats.forCharacter(id, rarity),
          CardStats.forCharacter(id, rarity),
        );
      }
    }
  });

  test('every stat stays within base x rarity x [0.85, 1.15]', () {
    for (var id = 1; id <= 826; id++) {
      for (final rarity in Rarity.values) {
        final s = CardStats.forCharacter(id, rarity);
        final m = rarity.statMultiplier;
        void check(int value, int base) => expect(
          value,
          inInclusiveRange(
            (base * m * 0.85).round(),
            (base * m * 1.15).round(),
          ),
        );
        check(s.hp, CardStats.baseHp);
        check(s.atk, CardStats.baseAtk);
        check(s.def, CardStats.baseDef);
        check(s.spd, CardStats.baseSpd);
      }
    }
  });

  test(
    'over ids 1-826: legendary avg > epic > rare > common for every stat',
    () {
      Map<String, double> averages(Rarity rarity) {
        final all = [
          for (var id = 1; id <= 826; id++) CardStats.forCharacter(id, rarity),
        ];
        double avg(int Function(CardStats) f) =>
            all.map(f).reduce((a, b) => a + b) / all.length;
        return {
          'hp': avg((s) => s.hp),
          'atk': avg((s) => s.atk),
          'def': avg((s) => s.def),
          'spd': avg((s) => s.spd),
        };
      }

      final byRarity = {for (final r in Rarity.values) r: averages(r)};
      for (final stat in ['hp', 'atk', 'def', 'spd']) {
        final values = Rarity.values.map((r) => byRarity[r]![stat]!).toList();
        for (var i = 1; i < values.length; i++) {
          expect(
            values[i],
            greaterThan(values[i - 1]),
            reason:
                '$stat: ${Rarity.values[i].name} vs '
                '${Rarity.values[i - 1].name}',
          );
        }
      }
    },
  );
}
