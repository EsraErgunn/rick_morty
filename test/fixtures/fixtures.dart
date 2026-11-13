import 'dart:convert';
import 'dart:io';

/// `test/fixtures/` içinden bir fikstürü çözülmüş JSON olarak okur.
/// `flutter test` paket kökünden çalışır, bu yüzden yol ona göredir.
Map<String, dynamic> loadFixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

/// API id'sine göre karakter fikstürleri.
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
