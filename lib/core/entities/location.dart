import 'package:equatable/equatable.dart';

/// A location (dimension map, stretch) [GM §10].
final class Location extends Equatable {
  const Location({
    required this.id,
    required this.name,
    required this.type,
    required this.dimension,
    required this.residentIds,
  });

  final int id;
  final String name;
  final String type;
  final String dimension;
  final List<int> residentIds;

  @override
  List<Object?> get props => [id, name, type, dimension, residentIds];
}
