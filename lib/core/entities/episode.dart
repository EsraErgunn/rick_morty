import 'package:equatable/equatable.dart';

/// An episode: one album page [GM §9].
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

  /// As given by the API, e.g. `December 2, 2013`.
  final String airDate;

  /// Season/episode code, e.g. `S01E01` (album sort key).
  final String code;
  final List<int> characterIds;

  @override
  List<Object?> get props => [id, name, airDate, code, characterIds];
}
