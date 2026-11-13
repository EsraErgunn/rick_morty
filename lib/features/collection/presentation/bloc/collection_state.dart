import 'package:equatable/equatable.dart';

import '../../../../core/game/card_type.dart';
import '../../../../core/game/rarity.dart';
import '../../domain/collection_repository.dart';

/// Koleksiyon verisinin yüklenme durumu.
enum CollectionStatus { initial, success }

/// Sıralama düzenleri (SPEC §2.4 AC2); varsayılan nadirlik (en yüksek önce).
enum CollectionSort { rarity, name, newest }

/// Koleksiyon ekranının durumu: kartlar, filtreler ve sıralama.
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

  /// Sahip olunan tüm kartlar (filtresiz).
  final List<CollectionEntry> entries;
  final int total;

  /// Boş küme = o boyutta filtre yok.
  final Set<Rarity> rarities;
  final Set<CardType> types;
  final CollectionSort sort;

  bool get hasFilter => rarities.isNotEmpty || types.isNotEmpty;

  /// Filtre ve sıralama sonrası kartlar.
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
