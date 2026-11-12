import 'package:fpdart/fpdart.dart';

import '../../../core/entities/character.dart';
import '../../../core/entities/episode.dart';
import '../../../core/entities/location.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/endpoints.dart';
import 'mappers.dart';

/// One page of each API list endpoint, already mapped to entities.
abstract interface class SyncRemoteDataSource {
  Future<Either<Failure, EntityPage<Character>>> characterPage(int page);
  Future<Either<Failure, EntityPage<Episode>>> episodePage(int page);
  Future<Either<Failure, EntityPage<Location>>> locationPage(int page);
}

class ApiSyncRemoteDataSource implements SyncRemoteDataSource {
  const ApiSyncRemoteDataSource(this._client);

  final ApiClient _client;

  Future<Either<Failure, EntityPage<T>>> _page<T>(
    String path,
    int page,
    Either<Failure, EntityPage<T>> Function(Map<String, dynamic>) parse,
  ) async =>
      (await _client.getJson(path, query: Endpoints.page(page))).flatMap(parse);

  @override
  Future<Either<Failure, EntityPage<Character>>> characterPage(int page) =>
      _page(Endpoints.characters, page, parseCharacterPage);

  @override
  Future<Either<Failure, EntityPage<Episode>>> episodePage(int page) =>
      _page(Endpoints.episodes, page, parseEpisodePage);

  @override
  Future<Either<Failure, EntityPage<Location>>> locationPage(int page) =>
      _page(Endpoints.locations, page, parseLocationPage);
}
