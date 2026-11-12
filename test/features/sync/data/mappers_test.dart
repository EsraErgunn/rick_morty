import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/entities/character.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/features/sync/data/mappers.dart';

import '../../../fixtures/fixtures.dart';

Character _character(int id) =>
    parseCharacter(loadCharacter(id)).getOrElse((f) => throw StateError('$f'));

void main() {
  group('character', () {
    test('every character fixture parses', () {
      for (final id in characterFixtures.keys) {
        expect(
          parseCharacter(loadCharacter(id)).isRight(),
          isTrue,
          reason: '$id',
        );
      }
    });

    test('Rick maps every field; episode URLs become ids', () {
      final rick = _character(1);
      expect(rick.id, 1);
      expect(rick.name, 'Rick Sanchez');
      expect(rick.status, 'Alive');
      expect(rick.species, 'Human');
      expect(rick.subtype, '');
      expect(rick.originName, 'Earth (C-137)');
      expect(rick.originId, 1);
      expect(rick.locationName, 'Citadel of Ricks');
      expect(rick.locationId, 3);
      expect(
        rick.imageUrl,
        'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
      );
      expect(rick.episodeCount, 51);
      expect(rick.episodeIds.take(2), [1, 2]);
    });

    test('unknown origin (empty URL) maps to a null id', () {
      final centaur = _character(63);
      expect(centaur.originName, 'unknown');
      expect(centaur.originId, isNull);
      expect(centaur.subtype, 'Centaur');
    });

    test('single-episode Conroy has exactly one episode id', () {
      expect(_character(71).episodeIds, [22]);
    });

    test('episode id list is unmodifiable', () {
      expect(() => _character(1).episodeIds.add(99), throwsUnsupportedError);
    });
  });

  group('pages', () {
    test('episode page: totals from info, 20 items, character URLs to ids', () {
      final page = parseEpisodePage(loadFixture('episode_page_1.json'))
          .getOrElse((f) => throw StateError('$f'));
      expect(page.count, 51);
      expect(page.pages, 3);
      expect(page.items, hasLength(20));
      final pilot = page.items.first;
      expect(pilot.id, 1);
      expect(pilot.name, 'Pilot');
      expect(pilot.code, 'S01E01');
      expect(pilot.airDate, 'December 2, 2013');
      expect(pilot.characterIds, hasLength(19));
      expect(pilot.characterIds.take(2), [1, 2]);
    });

    test('location page: totals, resident URLs to ids, empty residents ok', () {
      final page = parseLocationPage(loadFixture('location_page_1.json'))
          .getOrElse((f) => throw StateError('$f'));
      expect(page.count, 126);
      expect(page.pages, 7);
      final earth = page.items.first;
      expect(earth.name, 'Earth (C-137)');
      expect(earth.type, 'Planet');
      expect(earth.dimension, 'Dimension C-137');
      expect(earth.residentIds, hasLength(27));
      expect(page.items.firstWhere((l) => l.id == 12).residentIds, isEmpty);
    });
  });

  group('malformed input is a ParseFailure, never a crash', () {
    Map<String, dynamic> rick() => loadCharacter(1);

    test('missing field', () {
      final json = rick()..remove('name');
      expect(parseCharacter(json).getLeft().toNullable(), isA<ParseFailure>());
    });

    test('wrong type', () {
      final json = rick()..['id'] = '1';
      expect(parseCharacter(json).getLeft().toNullable(), isA<ParseFailure>());
    });

    test('episode URL without an id', () {
      final json = rick()
        ..['episode'] = ['https://rickandmortyapi.com/api/episode/'];
      expect(parseCharacter(json).getLeft().toNullable(), isA<ParseFailure>());
    });

    test('page without info', () {
      final json = loadFixture('episode_page_1.json')..remove('info');
      expect(
        parseEpisodePage(json).getLeft().toNullable(),
        isA<ParseFailure>(),
      );
    });

    test('page with one broken item fails the whole page', () {
      final json = loadFixture('location_page_1.json');
      ((json['results'] as List<dynamic>)[3] as Map<String, dynamic>).remove(
        'residents',
      );
      expect(
        parseLocationPage(json).getLeft().toNullable(),
        isA<ParseFailure>(),
      );
    });

    test('failure message names the field', () {
      final json = rick()..remove('species');
      final failure = parseCharacter(json).getLeft().toNullable()!;
      expect(failure.message, contains('species'));
    });
  });
}
