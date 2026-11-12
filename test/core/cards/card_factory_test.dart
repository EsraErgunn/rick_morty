import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/cards/card_factory.dart';
import 'package:portalcards/core/cards/rarity_pool.dart';
import 'package:portalcards/core/entities/character.dart';
import 'package:portalcards/core/game/card_stats.dart';
import 'package:portalcards/core/game/card_type.dart';
import 'package:portalcards/core/game/passives.dart';
import 'package:portalcards/core/game/rarity.dart';
import 'package:portalcards/features/sync/data/mappers.dart';

import '../../fixtures/fixtures.dart';

Character _character(int id) =>
    parseCharacter(loadCharacter(id)).getOrElse((f) => throw StateError('$f'));

void main() {
  group('CardFactory', () {
    test('Rick: legendary Human, no passive, GM 4 reference stats', () {
      final card = CardFactory.fromCharacter(_character(1));
      expect(card.name, 'Rick Sanchez');
      expect(card.rarity, Rarity.legendary);
      expect(card.type, CardType.human);
      expect(card.passive, Passive.none);
      expect(card.stats, const CardStats(hp: 152, atk: 66, def: 17, spd: 17));
      expect(card.episodeCount, 51);
      expect(card.originName, 'Earth (C-137)');
    });

    test('Conroy: common Robot with Zombi', () {
      final card = CardFactory.fromCharacter(_character(71));
      expect(card.rarity, Rarity.common);
      expect(card.type, CardType.robot);
      expect(card.passive, Passive.zombie);
      expect(card.stats, const CardStats(hp: 85, atk: 36, def: 13, spd: 11));
    });

    test('every fixture equals the core/game results (no own formula)', () {
      for (final id in characterFixtures.keys) {
        final c = _character(id);
        final card = CardFactory.fromCharacter(c);
        final rarity = Rarity.fromEpisodeCount(c.episodeCount);
        expect(card.rarity, rarity);
        expect(card.type, CardType.fromSpecies(c.species));
        expect(card.passive, Passive.fromStatus(c.status));
        expect(card.stats, CardStats.forCharacter(c.id, rarity));
        expect(card.imageUrl, c.imageUrl);
      }
    });
  });

  group('RarityPool', () {
    final characters = [
      for (final id in characterFixtures.keys) _character(id),
    ];

    test('covers every character exactly once', () {
      final pool = RarityPool.fromCharacters(characters);
      final all = [for (final r in Rarity.values) ...pool.ids(r)];
      expect(all, hasLength(characters.length));
      expect(all.toSet(), characters.map((c) => c.id).toSet());
      expect(pool.total, characters.length);
    });

    test('groups the fixtures by rarity, sorted by id', () {
      final pool = RarityPool.fromCharacters(characters);
      expect(pool.ids(Rarity.legendary), [1, 2]);
      expect(pool.ids(Rarity.epic), [23]);
      expect(pool.ids(Rarity.rare), [82, 86, 309]);
      expect(pool.ids(Rarity.common), [63, 71]);
    });

    test('an empty input gives empty lists for every rarity', () {
      final pool = RarityPool.fromCharacters(const []);
      for (final r in Rarity.values) {
        expect(pool.ids(r), isEmpty);
      }
    });
  });
}
