import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/game/passives.dart';

import '../../fixtures/fixtures.dart';

Passive _passiveOf(int id) =>
    Passive.fromStatus(loadCharacter(id)['status'] as String);

void main() {
  group('Passive.fromStatus', () {
    test('Alive has no passive', () {
      expect(Passive.fromStatus('Alive'), Passive.none);
    });

    test('Dead is Zombi', () {
      expect(Passive.fromStatus('Dead'), Passive.zombie);
    });

    test('unknown is Belirsiz', () {
      expect(Passive.fromStatus('unknown'), Passive.uncertain);
    });

    test('ignores case and spaces; anything else is no passive', () {
      expect(Passive.fromStatus(' DEAD '), Passive.zombie);
      expect(Passive.fromStatus('Unknown'), Passive.uncertain);
      expect(Passive.fromStatus(''), Passive.none);
    });

    test('Rick is Alive (no passive), Conroy is Dead (Zombi), '
        'Arcade Alien is unknown (Belirsiz)', () {
      expect(_passiveOf(1), Passive.none);
      expect(_passiveOf(71), Passive.zombie);
      expect(_passiveOf(23), Passive.uncertain);
    });
  });

  group('Zombi', () {
    test('revives with 30% of max HP', () {
      expect(Passives.zombieReviveHp(100), 30);
      expect(Passives.zombieReviveHp(94), 28); // 28.2
      expect(Passives.zombieReviveHp(135), 41); // 40.5 rounds up
    });

    test('revives with at least 1 HP', () {
      expect(Passives.zombieReviveHp(1), 1);
    });
  });

  group('Belirsiz', () {
    test('gives only x1.2 or x0.8', () {
      final random = Random(1);
      for (var i = 0; i < 1000; i++) {
        expect(
          Passives.attackMultiplier(Passive.uncertain, random),
          anyOf(1.2, 0.8),
        );
      }
    });

    test('is about 50/50 over 10,000 seeded rolls (+-2%)', () {
      final random = Random(42);
      var high = 0;
      const rolls = 10000;
      for (var i = 0; i < rolls; i++) {
        if (Passives.attackMultiplier(Passive.uncertain, random) == 1.2) high++;
      }
      expect(high / rolls, closeTo(0.5, 0.02));
    });

    test('same seed gives the same sequence', () {
      List<double> run() {
        final random = Random(7);
        return [
          for (var i = 0; i < 20; i++)
            Passives.attackMultiplier(Passive.uncertain, random),
        ];
      }

      expect(run(), run());
    });
  });

  test('none and Zombi deal x1.0 and do not consume randomness', () {
    final used = Random(3);
    final untouched = Random(3);
    expect(Passives.attackMultiplier(Passive.none, used), 1);
    expect(Passives.attackMultiplier(Passive.zombie, used), 1);
    expect(used.nextDouble(), untouched.nextDouble());
  });
}
