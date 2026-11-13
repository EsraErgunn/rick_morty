import 'package:equatable/equatable.dart';

import '../../../../core/game/card_type.dart';
import '../../../../core/game/rarity.dart';
import 'collection_state.dart';

sealed class CollectionEvent extends Equatable {
  const CollectionEvent();

  @override
  List<Object?> get props => [];
}

/// Page opened (or shown again): load the owned cards.
final class CollectionStarted extends CollectionEvent {
  const CollectionStarted();
}

/// Stored cards or deck changed (a portal, the card detail, a reset).
final class CollectionDataChanged extends CollectionEvent {
  const CollectionDataChanged();
}

/// A rarity chip tapped: add or remove it from the filter.
final class CollectionRarityToggled extends CollectionEvent {
  const CollectionRarityToggled(this.rarity);

  final Rarity rarity;

  @override
  List<Object?> get props => [rarity];
}

/// A type chip tapped: add or remove it from the filter.
final class CollectionTypeToggled extends CollectionEvent {
  const CollectionTypeToggled(this.type);

  final CardType type;

  @override
  List<Object?> get props => [type];
}

/// "Hepsi": clear every filter.
final class CollectionFiltersCleared extends CollectionEvent {
  const CollectionFiltersCleared();
}

final class CollectionSortChanged extends CollectionEvent {
  const CollectionSortChanged(this.sort);

  final CollectionSort sort;

  @override
  List<Object?> get props => [sort];
}
