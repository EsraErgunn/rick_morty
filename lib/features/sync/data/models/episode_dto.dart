import 'json_reader.dart';

/// API'nin döndürdüğü hâliyle `/episode` öğesi.
class EpisodeDto {
  const EpisodeDto({
    required this.id,
    required this.name,
    required this.airDate,
    required this.episode,
    required this.characterIds,
  });

  /// Bozuk bir öğe için [FormatException] fırlatır.
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

  /// `S01E01` gibi kod.
  final String episode;
  final List<int> characterIds;
}
