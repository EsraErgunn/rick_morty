import 'package:equatable/equatable.dart';

/// Deste ekranının olaylarının temel sınıfı.
sealed class DeckEvent extends Equatable {
  const DeckEvent();

  @override
  List<Object?> get props => [];
}

/// Deste sayfası açıldı: kartları ve desteyi yükle.
final class DeckStarted extends DeckEvent {
  const DeckStarted();
}

/// Kayıtlı kartlar veya deste değişti (burada ya da başka bir ekranda).
final class DeckDataChanged extends DeckEvent {
  const DeckDataChanged();
}

/// Sahip olunan bir karta dokunuldu: ilk boş slota girer.
final class DeckCardTapped extends DeckEvent {
  const DeckCardTapped(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Dolu bir slota dokunuldu: boşalır.
final class DeckSlotTapped extends DeckEvent {
  const DeckSlotTapped(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}
