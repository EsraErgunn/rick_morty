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

    test('rolls are in [0, 1] for every id and stat index', () {
      for (var id = 1; id <= 826; id++) {
        for (var k = 0; k < 4; k++) {
          expect(CardStats.statRoll(id, k), inInclusiveRange(0, 1));
        }
      }
    });
  });

  group('hand-computed values (independent calculation, GM 4)', () {
    test('Rick (id 1, legendary) is HP 135, ATK 32, DEF 17, SPD 13', () {
      expect(
        _fromFixture(1),
        const CardStats(hp: 135, atk: 32, def: 17, spd: 13),
      );
    });

    test('Morty (id 2, legendary) is HP 142, ATK 34, DEF 18, SPD 14', () {
      expect(
        _fromFixture(2),
        const CardStats(hp: 142, atk: 34, def: 18, spd: 14),
      );
    });

    test(
      'Conroy (id 71, common, 1 episode) is HP 94, ATK 22, DEF 12, SPD 9',
      () {
        expect(
          _fromFixture(71),
          const CardStats(hp: 94, atk: 22, def: 12, spd: 9),
        );
      },
    );

    test('Arcade Alien (id 23, epic) is HP 136, ATK 24, DEF 17, SPD 13', () {
      expect(
        _fromFixture(23),
        const CardStats(hp: 136, atk: 24, def: 17, spd: 13),
      );
    });

    test('Cyclops Rick (id 86, rare) is HP 121, ATK 22, DEF 16, SPD 12', () {
      expect(
        _fromFixture(86),
        const CardStats(hp: 121, atk: 22, def: 16, spd: 12),
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
