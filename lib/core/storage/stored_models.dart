import 'package:hive_ce/hive.dart';

import '../entities/character.dart';
import '../entities/episode.dart';
import '../entities/location.dart';
import 'hive_type_ids.dart';

part 'stored_models.g.dart';

// API varlıklarının depolama biçimleri. Varlıklar Hive'dan bağımsız kalır; bu
// sınıflar onlara ve onlardan dönüşüm yapar. Alan numaraları kalıcıdır: yeni alanları
// yeni numaralarla ekle, hiçbirini yeniden kullanma.

/// Hive'da saklanan karakter kaydı ([Character] varlığına dönüştürülür).
@HiveType(typeId: HiveTypeIds.storedCharacter)
class StoredCharacter {
  StoredCharacter({
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

  factory StoredCharacter.fromEntity(Character c) => StoredCharacter(
    id: c.id,
    name: c.name,
    status: c.status,
    species: c.species,
    subtype: c.subtype,
    gender: c.gender,
    originName: c.originName,
    originId: c.originId,
    locationName: c.locationName,
    locationId: c.locationId,
    imageUrl: c.imageUrl,
    episodeIds: c.episodeIds,
  );

  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String status;
  @HiveField(3)
  final String species;
  @HiveField(4)
  final String subtype;
  @HiveField(5)
  final String gender;
  @HiveField(6)
  final String originName;
  @HiveField(7)
  final int? originId;
  @HiveField(8)
  final String locationName;
  @HiveField(9)
  final int? locationId;
  @HiveField(10)
  final String imageUrl;
  @HiveField(11)
  final List<int> episodeIds;

  Character toEntity() => Character(
    id: id,
    name: name,
    status: status,
    species: species,
    subtype: subtype,
    gender: gender,
    originName: originName,
    originId: originId,
    locationName: locationName,
    locationId: locationId,
    imageUrl: imageUrl,
    episodeIds: List.unmodifiable(episodeIds),
  );
}

/// Hive'da saklanan bölüm kaydı ([Episode] varlığına dönüştürülür).
@HiveType(typeId: HiveTypeIds.storedEpisode)
class StoredEpisode {
  StoredEpisode({
    required this.id,
    required this.name,
    required this.airDate,
    required this.code,
    required this.characterIds,
  });

  factory StoredEpisode.fromEntity(Episode e) => StoredEpisode(
    id: e.id,
    name: e.name,
    airDate: e.airDate,
    code: e.code,
    characterIds: e.characterIds,
  );

  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String airDate;
  @HiveField(3)
  final String code;
  @HiveField(4)
  final List<int> characterIds;

  Episode toEntity() => Episode(
    id: id,
    name: name,
    airDate: airDate,
    code: code,
    characterIds: List.unmodifiable(characterIds),
  );
}

/// Hive'da saklanan konum kaydı ([Location] varlığına dönüştürülür).
@HiveType(typeId: HiveTypeIds.storedLocation)
class StoredLocation {
  StoredLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.dimension,
    required this.residentIds,
  });

  factory StoredLocation.fromEntity(Location l) => StoredLocation(
    id: l.id,
    name: l.name,
    type: l.type,
    dimension: l.dimension,
    residentIds: l.residentIds,
  );

  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String type;
  @HiveField(3)
  final String dimension;
  @HiveField(4)
  final List<int> residentIds;

  Location toEntity() => Location(
    id: id,
    name: name,
    type: type,
    dimension: dimension,
    residentIds: List.unmodifiable(residentIds),
  );
}
