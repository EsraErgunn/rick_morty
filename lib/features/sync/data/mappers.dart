import 'package:fpdart/fpdart.dart';

import '../../../core/entities/character.dart';
import '../../../core/entities/episode.dart';
import '../../../core/entities/location.dart';
import '../../../core/errors/failures.dart';
import 'models/character_dto.dart';
import 'models/episode_dto.dart';
import 'models/location_dto.dart';
import 'models/page_dto.dart';

/// API karakter DTO'sunu [Character] varlığına dönüştürür.
extension CharacterDtoMapper on CharacterDto {
  Character toEntity() => Character(
    id: id,
    name: name,
    status: status,
    species: species,
    subtype: type,
    gender: gender,
    originName: originName,
    originId: originId,
    locationName: locationName,
    locationId: locationId,
    imageUrl: image,
    episodeIds: List.unmodifiable(episodeIds),
  );
}

/// API bölüm DTO'sunu [Episode] varlığına dönüştürür.
extension EpisodeDtoMapper on EpisodeDto {
  Episode toEntity() => Episode(
    id: id,
    name: name,
    airDate: airDate,
    code: episode,
    characterIds: List.unmodifiable(characterIds),
  );
}

/// API konum DTO'sunu [Location] varlığına dönüştürür.
extension LocationDtoMapper on LocationDto {
  Location toEntity() => Location(
    id: id,
    name: name,
    type: type,
    dimension: dimension,
    residentIds: List.unmodifiable(residentIds),
  );
}

/// Kaynak toplamlarıyla birlikte ayrıştırılmış bir varlık sayfası.
typedef EntityPage<T> = ({int count, int pages, List<T> items});

Either<Failure, EntityPage<T>> _parsePage<D, T>(
  Map<String, dynamic> json,
  D Function(Map<String, dynamic>) fromJson,
  T Function(D) toEntity,
) {
  try {
    final page = PageDto.fromJson(json, fromJson);
    return right((
      count: page.count,
      pages: page.pages,
      items: [for (final dto in page.results) toEntity(dto)],
    ));
  } on FormatException catch (e) {
    return left(ParseFailure(e.message));
  }
}

Either<Failure, EntityPage<Character>> parseCharacterPage(
  Map<String, dynamic> json,
) => _parsePage(json, CharacterDto.fromJson, (d) => d.toEntity());

Either<Failure, EntityPage<Episode>> parseEpisodePage(
  Map<String, dynamic> json,
) => _parsePage(json, EpisodeDto.fromJson, (d) => d.toEntity());

Either<Failure, EntityPage<Location>> parseLocationPage(
  Map<String, dynamic> json,
) => _parsePage(json, LocationDto.fromJson, (d) => d.toEntity());

/// Tek bir `/character/{id}` nesnesi.
Either<Failure, Character> parseCharacter(Map<String, dynamic> json) {
  try {
    return right(CharacterDto.fromJson(json).toEntity());
  } on FormatException catch (e) {
    return left(ParseFailure(e.message));
  }
}
