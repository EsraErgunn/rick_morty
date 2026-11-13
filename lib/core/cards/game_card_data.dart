import 'package:equatable/equatable.dart';

import '../game/card_stats.dart';
import '../game/card_type.dart';
import '../game/featured.dart';
import '../game/passives.dart';
import '../game/rarity.dart';

/// Bir kartın gösterdiği her şey, kayıtlı bir karakterden türetilir (kendisi
/// asla kaydedilmez, SPEC §3).
final class GameCardData extends Equatable {
  const GameCardData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rarity,
    required this.type,
    required this.stats,
    required this.passive,
    required this.species,
    required this.status,
    required this.originName,
    required this.locationName,
    required this.episodeCount,
    this.signature,
  });

  final int id;
  final String name;
  final String imageUrl;
  final Rarity rarity;
  final CardType type;
  final CardStats stats;
  final Passive passive;

  // Arka yüz bilgileri (kart detay sayfası).
  final String species;
  final String status;
  final String originName;
  final String locationName;
  final int episodeCount;

  /// Öne çıkan karakterler için dolu [GM §12].
  final Signature? signature;

  bool get featured => signature != null;

  @override
  List<Object?> get props => [
    id,
    name,
    imageUrl,
    rarity,
    type,
    stats,
    passive,
    species,
    status,
    originName,
    locationName,
    episodeCount,
    signature,
  ];
}
