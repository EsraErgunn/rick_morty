import 'dart:convert';
import 'dart:io';

/// Reads a fixture from `test/fixtures/` as decoded JSON.
/// `flutter test` runs from the package root, so the path is relative to it.
Map<String, dynamic> loadFixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

/// Character fixtures by API id.
const Map<int, String> characterFixtures = {
  1: 'character_1_rick_sanchez.json',
  2: 'character_2_morty_smith.json',
  23: 'character_23_arcade_alien.json',
  63: 'character_63_centaur.json',
  71: 'character_71_conroy.json',
  82: 'character_82_cronenberg_rick.json',
  86: 'character_86_cyclops_rick.json',
  309: 'character_309_scrotian.json',
};

Map<String, dynamic> loadCharacter(int id) =>
    loadFixture(characterFixtures[id]!);
