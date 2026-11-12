import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  /// id → (name, episode count, species, status) as returned by the API.
  const expected = <int, (String, int, String, String)>{
    1: ('Rick Sanchez', 51, 'Human', 'Alive'),
    2: ('Morty Smith', 51, 'Human', 'Alive'),
    23: ('Arcade Alien', 5, 'Alien', 'unknown'),
    63: ('Centaur', 1, 'Mythological Creature', 'Alive'),
    71: ('Conroy', 1, 'Robot', 'Dead'),
    82: ('Cronenberg Rick', 2, 'Cronenberg', 'unknown'),
    86: ('Cyclops Rick', 3, 'Humanoid', 'Dead'),
    309: ('Scrotian', 4, 'Animal', 'Alive'),
  };

  group('character fixtures', () {
    for (final MapEntry(key: id, value: (name, episodes, species, status))
        in expected.entries) {
      test('$id $name: $episodes episodes, $species, $status', () {
        final json = loadCharacter(id);
        expect(json['id'], id);
        expect(json['name'], name);
        expect((json['episode'] as List<dynamic>).length, episodes);
        expect(json['species'], species);
        expect(json['status'], status);
        expect(json['image'], startsWith('https://'));
      });
    }

    test('cover all 3 statuses', () {
      final statuses = expected.values.map((e) => e.$4).toSet();
      expect(statuses, {'Alive', 'Dead', 'unknown'});
    });

    test('include a single-episode character', () {
      expect(expected.values.where((e) => e.$2 == 1), isNotEmpty);
    });
  });

  group('page fixtures', () {
    for (final name in ['episode_page_1.json', 'location_page_1.json']) {
      test('$name has info and 20 results', () {
        final json = loadFixture(name);
        final info = json['info'] as Map<String, dynamic>;
        expect(info['count'], isA<int>());
        expect(info['pages'], isA<int>());
        expect(json['results'] as List<dynamic>, hasLength(20));
      });
    }

    test('episode characters and location residents are URL lists', () {
      final episode =
          (loadFixture('episode_page_1.json')['results'] as List<dynamic>).first
              as Map<String, dynamic>;
      final location =
          (loadFixture('location_page_1.json')['results'] as List<dynamic>)
                  .first
              as Map<String, dynamic>;
      expect(
        episode['characters'] as List<dynamic>,
        everyElement(startsWith('https://rickandmortyapi.com/api/character/')),
      );
      expect(
        location['residents'] as List<dynamic>,
        everyElement(startsWith('https://rickandmortyapi.com/api/character/')),
      );
    });
  });
}
