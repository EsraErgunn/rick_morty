import 'package:equatable/equatable.dart';

import '../../../../core/game/card_type.dart';
import '../../../../core/game/rarity.dart';
import 'collection_state.dart';

/// Koleksiyon ekranının olaylarının temel sınıfı.
sealed class CollectionEvent extends Equatable {
  const CollectionEvent();

  @override
  List<Object?> get props => [];
}

/// Sayfa açıldı (ya da yeniden gösterildi): sahip olunan kartları yükle.
final class CollectionStarted extends CollectionEvent {
  const CollectionStarted();
}

/// Kayıtlı kartlar veya deste değişti (bir portal, kart detayı, sıfırlama).
final class CollectionDataChanged extends CollectionEvent {
  const CollectionDataChanged();
}

/// Bir nadirlik çipine dokunuldu: filtreye ekle ya da çıkar.
final class CollectionRarityToggled extends CollectionEvent {
  const CollectionRarityToggled(this.rarity);

  final Rarity rarity;

  @override
  List<Object?> get props => [rarity];
}

/// Bir tip çipine dokunuldu: filtreye ekle ya da çıkar.
final class CollectionTypeToggled extends CollectionEvent {
  const CollectionTypeToggled(this.type);

  final CardType type;

  @override
  List<Object?> get props => [type];
}

/// "Hepsi": tüm filtreleri temizle.
final class CollectionFiltersCleared extends CollectionEvent {
  const CollectionFiltersCleared();
}

/// Sıralama düzeni değiştirildi.
final class CollectionSortChanged extends CollectionEvent {
  const CollectionSortChanged(this.sort);

  final CollectionSort sort;

  @override
  List<Object?> get props => [sort];
}
