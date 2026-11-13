import 'package:equatable/equatable.dart';

/// Kart detay ekranının olaylarının temel sınıfı.
sealed class CardDetailEvent extends Equatable {
  const CardDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Kart detay sayfası açıldı: kartı ve sahipliği yükle.
final class CardDetailStarted extends CardDetailEvent {
  const CardDetailStarted();
}

/// "Desteye ekle" / "Desteden çıkar".
final class CardDeckToggled extends CardDetailEvent {
  const CardDeckToggled();
}
