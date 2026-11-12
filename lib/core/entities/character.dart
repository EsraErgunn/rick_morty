import 'package:equatable/equatable.dart';

/// A character as the game uses it, mapped from the API.
/// Card data (rarity, type, stats) is derived from it by `core/game`.
final class Character extends Equatable {
  const Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.subtype,
    required this.gender,
    required this.originName,
    required this.originId,
    required this.locationName,
    required this.locationId,
    required this.imageUrl,
    required this.episodeIds,
  });

  final int id;
  final String name;

  /// API status: `Alive`, `Dead` or `unknown`.
  final String status;
  final String species;

  /// API `type` (free text sub-species, often empty).
  final String subtype;
  final String gender;
  final String originName;

  /// Null when the origin is unknown (empty URL in the API).
  final int? originId;
  final String locationName;
  final int? locationId;
  final String imageUrl;
  final List<int> episodeIds;

  int get episodeCount => episodeIds.length;

  @override
  List<Object?> get props => [
    id,
    name,
    status,
    species,
    subtype,
    gender,
    originName,
    originId,
    locationName,
    locationId,
    imageUrl,
    episodeIds,
  ];
}
