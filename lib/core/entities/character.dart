import 'package:equatable/equatable.dart';

/// Oyunun kullandığı hâliyle bir karakter, API'den eşlenir.
/// Kart verisi (nadirlik, tip, istatistikler) `core/game` tarafından bundan türetilir.
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

  /// API durumu: `Alive`, `Dead` veya `unknown`.
  final String status;
  final String species;

  /// API `type` alanı (serbest metin alt tür, çoğu zaman boş).
  final String subtype;
  final String gender;
  final String originName;

  /// Köken bilinmiyorsa null (API'de boş URL).
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
