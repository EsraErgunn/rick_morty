import 'package:fpdart/fpdart.dart';
import 'package:portalcards/core/entities/character.dart';
import 'package:portalcards/core/entities/episode.dart';
import 'package:portalcards/core/entities/location.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/features/sync/data/mappers.dart';
import 'package:portalcards/features/sync/data/remote_data_source.dart';

/// Gerçeğe benzer toplamlarla bellek içi API, sayfa başına 20 öğe.
/// [failOnCall] o çağrının (1'den başlar, tüm kaynaklar genelinde) bir kez başarısız olmasını sağlar.
class FakeSyncRemote implements SyncRemoteDataSource {
  FakeSyncRemote({
    this.characters = 45,
    this.episodes = 21,
    this.locations = 5,
    this.failOnCall,
  });

  final int characters;
  final int episodes;
  final int locations;
  int? failOnCall;

  /// Her istek `'<resource> <page>'` olarak, sırayla.
  final List<String> calls = [];

  static const int pageSize = 20;

  Either<Failure, EntityPage<T>> _page<T>(
    String key,
    int page,
    int count,
    T Function(int id) build,
  ) {
    calls.add('$key $page');
    if (failOnCall == calls.length) {
      failOnCall = null;
      return left(const NetworkFailure());
    }
    final pages = (count + pageSize - 1) ~/ pageSize;
    final first = (page - 1) * pageSize + 1;
    final last = (page * pageSize).clamp(0, count);
    return right((
      count: count,
      pages: pages,
      items: [for (var id = first; id <= last; id++) build(id)],
    ));
  }

  @override
  Future<Either<Failure, EntityPage<Character>>> characterPage(
    int page,
  ) async => _page('character', page, characters, character);

  @override
  Future<Either<Failure, EntityPage<Episode>>> episodePage(int page) async =>
      _page('episode', page, episodes, episode);

  @override
  Future<Either<Failure, EntityPage<Location>>> locationPage(int page) async =>
      _page('location', page, locations, location);

  static Character character(int id) => Character(
    id: id,
    name: 'Character $id',
    status: 'Alive',
    species: 'Human',
    subtype: '',
    gender: 'Male',
    originName: 'unknown',
    originId: null,
    locationName: 'Earth',
    locationId: 1,
    imageUrl: 'https://rickandmortyapi.com/api/character/avatar/$id.jpeg',
    episodeIds: const [1],
  );

  static Episode episode(int id) => Episode(
    id: id,
    name: 'Episode $id',
    airDate: 'December 2, 2013',
    code: 'S01E${id.toString().padLeft(2, '0')}',
    characterIds: const [1],
  );

  static Location location(int id) => Location(
    id: id,
    name: 'Location $id',
    type: 'Planet',
    dimension: 'unknown',
    residentIds: const [],
  );
}
