import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/game/portal_roll.dart';
import 'package:portalcards/core/game/rarity.dart';

/// 100 common, 40 rare, 20 epic, 4 legendary ids.
Map<Rarity, List<int>> _bigPool() => {
  Rarity.common: [for (var i = 0; i < 100; i++) 1000 + i],
  Rarity.rare: [for (var i = 0; i < 40; i++) 2000 + i],
  Rarity.epic: [for (var i = 0; i < 20; i++) 3000 + i],
  Rarity.legendary: [1, 2, 3, 4],
};

void main() {
  test('chances add up to 100 %', () {
    expect(
      PortalRoll.chances.values.reduce((a, b) => a + b),
      closeTo(1.0, 1e-9),
    );
  });

  test('10,000 seeded rolls: 60 / 28 / 10 / 2 % (+-2 %)', () {
    const n = 10000;
    final rnd = Random(7);
    final c = {for (final r in Rarity.values) r: 0};
    for (var i = 0; i < n; i++) {
      final r = PortalRoll.rollRarity(rnd);
      c[r] = c[r]! + 1;
    }
    for (final r in Rarity.values) {
      expect(c[r]! / n, closeTo(PortalRoll.chances[r]!, 0.02), reason: r.name);
    }
  });

  test('same seed, same picks', () {
    List<int> run() {
      final random = Random(99);
      return [
        for (var i = 0; i < 20; i++)
          PortalRoll.pick(
            pool: _bigPool(),
            owned: const {},
            portalsOpened: 10,
            forceLegendary: false,
            random: random,
          ).characterId,
      ];
    }

    expect(run(), run());
  });

  group('first three portals never give a duplicate [GM 7.1]', () {
    test('small pool (3 commons), 1,000 seeds: three distinct cards', () {
      final pool = {
        Rarity.common: [10, 11, 12],
        Rarity.rare: [20],
        Rarity.epic: [30],
        Rarity.legendary: [40],
      };
      for (var seed = 0; seed < 1000; seed++) {
        final random = Random(seed);
        final owned = <int>{};
        for (var portal = 0; portal < 3; portal++) {
          final pick = PortalRoll.pick(
            pool: pool,
            owned: owned,
            portalsOpened: portal,
            forceLegendary: false,
            random: random,
          );
          expect(pick.isDuplicate, isFalse, reason: 'seed $seed');
          expect(owned.add(pick.characterId), isTrue, reason: 'seed $seed');
        }
      }
    });

    test('edge (not reachable with real data): commons used up and the '
        'roll is common → no lower rarity, so a duplicate (GM 7.3 steps '
        'down only)', () {
      final pool = {
        Rarity.common: [10],
        Rarity.rare: [20],
        Rarity.epic: <int>[],
        Rarity.legendary: <int>[],
      };
      // Seed whose first roll is common (60 %).
      final seed = List.generate(
        50,
        (i) => i,
      ).firstWhere((s) => PortalRoll.rollRarity(Random(s)) == Rarity.common);
      final pick = PortalRoll.pick(
        pool: pool,
        owned: {10},
        portalsOpened: 1,
        forceLegendary: false,
        random: Random(seed),
      );
      expect(pick.isDuplicate, isTrue);
    });

    test('the 4th portal may give a duplicate again', () {
      final pool = {
        Rarity.common: [10],
        Rarity.rare: <int>[],
        Rarity.epic: <int>[],
        Rarity.legendary: <int>[],
      };
      final pick = PortalRoll.pick(
        pool: pool,
        owned: {10},
        portalsOpened: 3,
        forceLegendary: false,
        random: Random(1),
      );
      expect(pick.isDuplicate, isTrue);
    });
  });

  group('step-down when a rarity is used up [GM 7.3]', () {
    test('legendary → epic → rare → common, in that order', () {
      final pool = _bigPool();
      final ownedAllButCommon = {
        ...pool[Rarity.legendary]!,
        ...pool[Rarity.epic]!,
        ...pool[Rarity.rare]!,
      };
      final pick = PortalRoll.pick(
        pool: pool,
        owned: ownedAllButCommon,
        portalsOpened: 0,
        forceLegendary: true,
        random: Random(3),
      );
      expect(pick.rolled, Rarity.legendary);
      expect(pick.rarity, Rarity.common);
      expect(pick.isDuplicate, isFalse);
    });

    test('only one step down when the next rarity has a free card', () {
      final pool = _bigPool();
      final pick = PortalRoll.pick(
        pool: pool,
        owned: {...pool[Rarity.legendary]!},
        portalsOpened: 1,
        forceLegendary: true,
        random: Random(3),
      );
      expect(pick.rarity, Rarity.epic);
    });

    test('owning everything: a normal duplicate of the rolled rarity', () {
      final pool = _bigPool();
      final all = {for (final ids in pool.values) ...ids};
      final pick = PortalRoll.pick(
        pool: pool,
        owned: all,
        portalsOpened: 0,
        forceLegendary: true,
        random: Random(3),
      );
      expect(pick.rarity, Rarity.legendary);
      expect(pick.isDuplicate, isTrue);
    });
  });

  group('demo override [GM 7.2]', () {
    test('forced legendary skips the roll and still picks a legendary', () {
      final pick = PortalRoll.pick(
        pool: _bigPool(),
        owned: const {},
        portalsOpened: 20,
        forceLegendary: true,
        random: Random(5),
      );
      expect(pick.rolled, Rarity.legendary);
      expect(pick.rarity, Rarity.legendary);
      expect([1, 2, 3, 4], contains(pick.characterId));
    });
  });

  test('an empty rarity pool steps down, then up', () {
    final pool = {
      Rarity.common: <int>[],
      Rarity.rare: <int>[],
      Rarity.epic: [30],
      Rarity.legendary: <int>[],
    };
    for (var seed = 0; seed < 50; seed++) {
      final pick = PortalRoll.pick(
        pool: pool,
        owned: const {},
        portalsOpened: 10,
        forceLegendary: false,
        random: Random(seed),
      );
      expect(pick.characterId, 30);
    }
  });

  group('the first portal gives Rick [GM 7.1, 2026-11-13]', () {
    final pool = {
      Rarity.common: [10, 11, 12],
      Rarity.legendary: [1, 2, 3],
    };

    test('a new player gets Rick on every seed', () {
      for (var seed = 0; seed < 200; seed++) {
        final pick = PortalRoll.pick(
          pool: pool,
          owned: const {},
          portalsOpened: 0,
          forceLegendary: false,
          random: Random(seed),
        );
        expect(pick.characterId, PortalRoll.starterCharacterId);
        expect(pick.rarity, Rarity.legendary);
        expect(pick.isDuplicate, isFalse);
      }
    });

    test('the second portal rolls normally', () {
      final ids = {
        for (var seed = 0; seed < 200; seed++)
          PortalRoll.pick(
            pool: pool,
            owned: const {1},
            portalsOpened: 1,
            forceLegendary: false,
            random: Random(seed),
          ).characterId,
      };
      expect(ids, isNot(contains(PortalRoll.starterCharacterId)));
    });

    test('a player who already owns Rick rolls normally', () {
      final pick = PortalRoll.pick(
        pool: pool,
        owned: const {1},
        portalsOpened: 0,
        forceLegendary: false,
        random: Random(3),
      );
      expect(pick.characterId, isNot(PortalRoll.starterCharacterId));
    });
  });
}
