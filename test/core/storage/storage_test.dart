import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:portalcards/core/storage/api_data_store.dart';
import 'package:portalcards/core/storage/hive_init.dart';
import 'package:portalcards/core/storage/hive_type_ids.dart';
import 'package:portalcards/features/sync/data/mappers.dart';

import '../../fixtures/fixtures.dart';
import 'hive_test_helper.dart';

void main() {
  useTempHive();

  final characters = [
    for (final id in characterFixtures.keys)
      parseCharacter(loadCharacter(id))
          .getOrElse((f) => throw StateError('$f')),
  ];
  final episodes = parseEpisodePage(loadFixture('episode_page_1.json'))
      .getOrElse((f) => throw StateError('$f'))
      .items;
  final locations = parseLocationPage(loadFixture('location_page_1.json'))
      .getOrElse((f) => throw StateError('$f'))
      .items;

  test('write, close and reopen returns equal entities', () async {
    final store = await ApiDataStore.open();
    await store.putCharacters(characters);
    await store.putEpisodes(episodes);
    await store.putLocations(locations);
    await store.close();
    await Hive.close();

    final reopened = await ApiDataStore.open();
    expect(reopened.characterCount, characters.length);
    expect(reopened.episodeCount, 20);
    expect(reopened.locationCount, 20);
    for (final c in characters) {
      expect(reopened.character(c.id), c);
    }
    expect(reopened.episodes.toList(), episodes);
    expect(reopened.locations.toList(), locations);
  });

  test('null origin and empty resident lists survive a round trip', () async {
    final store = await ApiDataStore.open();
    await store.putCharacters(characters);
    await store.putLocations(locations);
    await store.close();
    await Hive.close();

    final reopened = await ApiDataStore.open();
    expect(reopened.character(63)!.originId, isNull);
    expect(reopened.location(12)!.residentIds, isEmpty);
  });

  test('writing the same page twice keeps one copy per id', () async {
    final store = await ApiDataStore.open();
    await store.putEpisodes(episodes);
    await store.putEpisodes(episodes);
    expect(store.episodeCount, 20);
  });

  test('missing id returns null', () async {
    final store = await ApiDataStore.open();
    expect(store.character(424242), isNull);
  });

  test('box names follow the architecture rules', () {
    expect(
      [
        HiveBoxes.characters,
        HiveBoxes.episodes,
        HiveBoxes.locations,
        HiveBoxes.collection,
        HiveBoxes.player,
      ],
      ['characters', 'episodes', 'locations', 'collection', 'player'],
    );
  });

  test('type ids are unique and only defined in hive_type_ids.dart', () {
    final source = File('lib/core/storage/hive_type_ids.dart')
        .readAsStringSync();
    final ids = RegExp(r'static const int \w+ = (\d+);')
        .allMatches(source)
        .map((m) => int.parse(m.group(1)!))
        .toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, contains(HiveTypeIds.storedCharacter));

    final literal = RegExp(r'typeId:\s*\d');
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
        .where((f) => literal.hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });
}
