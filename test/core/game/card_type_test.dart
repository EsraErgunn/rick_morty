import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/game/card_type.dart';

import '../../fixtures/fixtures.dart';

CardType _typeOf(int id) =>
    CardType.fromSpecies(loadCharacter(id)['species'] as String);

void main() {
  group('CardType.fromSpecies', () {
    const cases = {
      'Human': CardType.human,
      'Humanoid': CardType.human,
      'Robot': CardType.robot,
      'Alien': CardType.alien,
      'Animal': CardType.beast,
      'Mythological Creature': CardType.myth,
      'Cronenberg': CardType.neutral,
      'Disease': CardType.neutral,
      'Poopybutthole': CardType.neutral,
      'unknown': CardType.neutral,
      'Something New': CardType.neutral,
      '': CardType.neutral,
    };
    for (final MapEntry(key: species, value: type) in cases.entries) {
      test('"$species" is ${type.name}', () {
        expect(CardType.fromSpecies(species), type);
      });
    }

    test('ignores case and surrounding spaces', () {
      expect(CardType.fromSpecies('  hUmAnOiD '), CardType.human);
      expect(CardType.fromSpecies('mythological creature'), CardType.myth);
    });

    test('fixtures cover all six types', () {
      expect(
        characterFixtures.keys.map(_typeOf).toSet(),
        CardType.values.toSet(),
      );
    });

    test('Cyclops Rick (Humanoid) is Human', () {
      expect(_typeOf(86), CardType.human);
    });
  });

  group('type advantage', () {
    test('Human attacking Robot is super effective', () {
      expect(
        Effectiveness.of(CardType.human, CardType.robot),
        Effectiveness.superEffective,
      );
    });

    test('Robot attacking Alien is super effective', () {
      expect(
        Effectiveness.of(CardType.robot, CardType.alien),
        Effectiveness.superEffective,
      );
    });

    test('Alien attacking Human is super effective', () {
      expect(
        Effectiveness.of(CardType.alien, CardType.human),
        Effectiveness.superEffective,
      );
    });

    test('Robot attacking Human is not very effective', () {
      expect(
        Effectiveness.of(CardType.robot, CardType.human),
        Effectiveness.notVeryEffective,
      );
    });

    test('Human attacking Alien is not very effective', () {
      expect(
        Effectiveness.of(CardType.human, CardType.alien),
        Effectiveness.notVeryEffective,
      );
    });

    test('same type is normal', () {
      for (final t in CardType.values) {
        expect(Effectiveness.of(t, t), Effectiveness.normal);
      }
    });

    test('Beast, Myth and Neutral are normal against and from every type', () {
      const special = [CardType.beast, CardType.myth, CardType.neutral];
      for (final s in special) {
        for (final t in CardType.values) {
          expect(Effectiveness.of(s, t), Effectiveness.normal);
          expect(Effectiveness.of(t, s), Effectiveness.normal);
        }
      }
    });

    test('multipliers are x1.5, x0.75 and x1.0', () {
      expect(typeMultiplier(CardType.human, CardType.robot), 1.5);
      expect(typeMultiplier(CardType.robot, CardType.human), 0.75);
      expect(typeMultiplier(CardType.beast, CardType.alien), 1);
    });

    test('full 6x6 table has exactly 3 advantages and 3 disadvantages', () {
      final all = [
        for (final a in CardType.values)
          for (final d in CardType.values) Effectiveness.of(a, d),
      ];
      expect(all.where((e) => e == Effectiveness.superEffective), hasLength(3));
      expect(
        all.where((e) => e == Effectiveness.notVeryEffective),
        hasLength(3),
      );
    });
  });
}
