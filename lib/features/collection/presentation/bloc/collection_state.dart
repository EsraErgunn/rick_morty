import 'package:equatable/equatable.dart';

import '../../../../core/game/card_type.dart';
import '../../../../core/game/rarity.dart';
import '../../domain/collection_repository.dart';

enum CollectionStatus { initial, success }

/// Sort orders (SPEC §2.4 AC2); rarity (highest first) is the default.
enum CollectionSort { rarity, name, newest }

final class CollectionState extends Equatable {
  const CollectionState({
    this.status = CollectionStatus.initial,
    this.entries = const [],
    this.total = 0,
    this.rarities = const {},
    this.types = const {},
    this.sort = CollectionSort.rarity,
  });

  final CollectionStatus status;

  /// Every owned card (unfiltered).
  final List<CollectionEntry> entries;
  final int total;

  /// Empty set = no filter on that dimension.
  final Set<Rarity> rarities;
  final Set<CardType> types;
  final CollectionSort sort;

  bool get hasFilter => rarities.isNotEmpty || types.isNotEmpty;

  /// Cards after filters and sort.
  List<CollectionEntry> get visible {
    final list = [
      for (final e in entries)
        if ((rarities.isEmpty || rarities.contains(e.card.rarity)) &&
            (types.isEmpty || types.contains(e.card.type)))
          e,
    ];
    int byName(CollectionEntry a, CollectionEntry b) =>
        a.card.name.toLowerCase().compareTo(b.card.name.toLowerCase());
    list.sort(switch (sort) {
      CollectionSort.rarity => (a, b) {
        final r = b.card.rarity.index.compareTo(a.card.rarity.index);
        return r != 0 ? r : byName(a, b);
      },
      CollectionSort.name => byName,
      CollectionSort.newest => (a, b) => b.obtainedAt.compareTo(a.obtainedAt),
    });
    return list;
  }

  CollectionState copyWith({
    CollectionStatus? status,
    List<CollectionEntry>? entries,
    int? total,
    Set<Rarity>? rarities,
    Set<CardType>? types,
    CollectionSort? sort,
  }) => CollectionState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
    total: total ?? this.total,
    rarities: rarities ?? this.rarities,
    types: types ?? this.types,
    sort: sort ?? this.sort,
  );

  @override
  List<Object?> get props => [status, entries, total, rarities, types, sort];
}
