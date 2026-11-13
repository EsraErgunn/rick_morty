import 'json_reader.dart';

/// API'nin döndürdüğü hâliyle `/character` öğesi.
class CharacterDto {
  const CharacterDto({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.type,
    required this.gender,
    required this.originName,
    required this.originId,
    required this.locationName,
    required this.locationId,
    required this.image,
    required this.episodeIds,
  });

  /// Bozuk bir öğe için [FormatException] fırlatır.
  factory CharacterDto.fromJson(Map<String, dynamic> json) {
    final origin = json.object('origin');
    final location = json.object('location');
    return CharacterDto(
      id: json.field<int>('id'),
      name: json.field<String>('name'),
      status: json.field<String>('status'),
      species: json.field<String>('species'),
      type: json.field<String>('type'),
      gender: json.field<String>('gender'),
      originName: origin.field<String>('name'),
      originId: origin.optionalIdFromUrl('url'),
      locationName: location.field<String>('name'),
      locationId: location.optionalIdFromUrl('url'),
      image: json.field<String>('image'),
      episodeIds: json.idsFromUrls('episode'),
    );
  }

  final int id;
  final String name;
  final String status;
  final String species;
  final String type;
  final String gender;
  final String originName;
  final int? originId;
  final String locationName;
  final int? locationId;
  final String image;
  final List<int> episodeIds;
}
