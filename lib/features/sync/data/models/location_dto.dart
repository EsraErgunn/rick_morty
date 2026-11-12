import 'json_reader.dart';

/// `/location` item as returned by the API.
class LocationDto {
  const LocationDto({
    required this.id,
    required this.name,
    required this.type,
    required this.dimension,
    required this.residentIds,
  });

  /// Throws [FormatException] for a malformed item.
  factory LocationDto.fromJson(Map<String, dynamic> json) => LocationDto(
    id: json.field<int>('id'),
    name: json.field<String>('name'),
    type: json.field<String>('type'),
    dimension: json.field<String>('dimension'),
    residentIds: json.idsFromUrls('residents'),
  );

  final int id;
  final String name;
  final String type;
  final String dimension;
  final List<int> residentIds;
}
