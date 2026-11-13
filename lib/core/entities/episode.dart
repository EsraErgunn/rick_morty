import 'package:equatable/equatable.dart';

/// Bir bölüm: bir albüm sayfası [GM §9].
final class Episode extends Equatable {
  const Episode({
    required this.id,
    required this.name,
    required this.airDate,
    required this.code,
    required this.characterIds,
  });

  final int id;
  final String name;

  /// API'nin verdiği hâliyle, ör. `December 2, 2013`.
  final String airDate;

  /// Sezon/bölüm kodu, ör. `S01E01` (albüm sıralama anahtarı).
  final String code;
  final List<int> characterIds;

  @override
  List<Object?> get props => [id, name, airDate, code, characterIds];
}
