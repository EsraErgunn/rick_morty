import 'package:hive_ce/hive.dart';

import '../entities/character.dart';
import '../entities/episode.dart';
import '../entities/location.dart';
import 'hive_init.dart';
import 'stored_models.dart';

/// API verilerinin yerel kopyası: API id'sine göre anahtarlanmış `characters`, `episodes`,
/// `locations` kutuları. Metotlar Hive hatası fırlatabilir; repository'ler bunları yakalar
/// ve bir `StorageFailure` döndürür.
class ApiDataStore {
  ApiDataStore._(this._characters, this._episodes, this._locations);

  static Future<ApiDataStore> open() async => ApiDataStore._(
    await Hive.openBox<StoredCharacter>(HiveBoxes.characters),
    await Hive.openBox<StoredEpisode>(HiveBoxes.episodes),
    await Hive.openBox<StoredLocation>(HiveBoxes.locations),
  );

  final Box<StoredCharacter> _characters;
  final Box<StoredEpisode> _episodes;
  final Box<StoredLocation> _locations;

  int get characterCount => _characters.length;
  int get episodeCount => _episodes.length;
  int get locationCount => _locations.length;

  /// Bir sayfayı tek seferde yazar (sayfa başına bir disk yazımı).
  Future<void> putCharacters(Iterable<Character> items) => _characters.putAll({
    for (final c in items) c.id: StoredCharacter.fromEntity(c),
  });

  Future<void> putEpisodes(Iterable<Episode> items) => _episodes.putAll({
    for (final e in items) e.id: StoredEpisode.fromEntity(e),
  });

  Future<void> putLocations(Iterable<Location> items) => _locations.putAll({
    for (final l in items) l.id: StoredLocation.fromEntity(l),
  });

  Character? character(int id) => _characters.get(id)?.toEntity();
  Episode? episode(int id) => _episodes.get(id)?.toEntity();
  Location? location(int id) => _locations.get(id)?.toEntity();

  Iterable<Character> get characters =>
      _characters.values.map((c) => c.toEntity());
  Iterable<Episode> get episodes => _episodes.values.map((e) => e.toEntity());
  Iterable<Location> get locations =>
      _locations.values.map((l) => l.toEntity());

  Future<void> close() async {
    await _characters.close();
    await _episodes.close();
    await _locations.close();
  }
}
