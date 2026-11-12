import 'json_reader.dart';

/// `/episode` item as returned by the API.
class EpisodeDto {
  const EpisodeDto({
    required this.id,
    required this.name,
    required this.airDate,
    required this.episode,
    required this.characterIds,
  });

  /// Throws [FormatException] for a malformed item.
  factory EpisodeDto.fromJson(Map<String, dynamic> json) => EpisodeDto(
    id: json.field<int>('id'),
    name: json.field<String>('name'),
    airDate: json.field<String>('air_date'),
    episode: json.field<String>('episode'),
    characterIds: json.idsFromUrls('characters'),
  );

  final int id;
  final String name;
  final String airDate;

  /// Code like `S01E01`.
  final String episode;
  final List<int> characterIds;
}
