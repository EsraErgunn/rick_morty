import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/game/rarity.dart';

import '../../fixtures/fixtures.dart';

int _episodes(int id) => (loadCharacter(id)['episode'] as List<dynamic>).length;

void main() {
  group('Rarity.fromEpisodeCount boundaries', () {
    const cases = {
      1: Rarity.common,
      2: Rarity.rare,
      4: Rarity.rare,
      5: Rarity.epic,
      19: Rarity.epic,
      20: Rarity.legendary,
      51: Rarity.legendary,
    };
    for (final MapEntry(key: episodes, value: rarity) in cases.entries) {
      test('$episodes episodes is ${rarity.name}', () {
        expect(Rarity.fromEpisodeCount(episodes), rarity);
      });
    }

    test('0 episodes (never in the API) falls back to common', () {
      expect(Rarity.fromEpisodeCount(0), Rarity.common);
    });
  });

  group('fixtures', () {
    test('Rick (51 episodes) is legendary', () {
      expect(Rarity.fromEpisodeCount(_episodes(1)), Rarity.legendary);
    });

    test('Morty (51 episodes) is legendary', () {
      expect(Rarity.fromEpisodeCount(_episodes(2)), Rarity.legendary);
    });

    test('Arcade Alien (5 episodes) is epic', () {
      expect(Rarity.fromEpisodeCount(_episodes(23)), Rarity.epic);
    });

    test('Scrotian (4 episodes) is rare', () {
      expect(Rarity.fromEpisodeCount(_episodes(309)), Rarity.rare);
    });

    test('Conroy (1 episode) is common', () {
      expect(Rarity.fromEpisodeCount(_episodes(71)), Rarity.common);
    });

    test('fixtures cover all four rarities', () {
      final rarities = characterFixtures.keys
          .map((id) => Rarity.fromEpisodeCount(_episodes(id)))
          .toSet();
      expect(rarities, Rarity.values.toSet());
    });
  });

  test('stat multipliers are 1.00 / 1.15 / 1.30 / 1.50', () {
    expect(Rarity.values.map((r) => r.statMultiplier), [1, 1.15, 1.3, 1.5]);
  });

  test('holo strength is 0 / 0.35 / 0.65 / 1.0', () {
    expect(Rarity.values.map((r) => r.holoStrength), [0, 0.35, 0.65, 1]);
  });

  test('rarities are ordered from common to legendary', () {
    expect(Rarity.values, [
      Rarity.common,
      Rarity.rare,
      Rarity.epic,
      Rarity.legendary,
    ]);
  });
}
