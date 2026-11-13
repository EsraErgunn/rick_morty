import 'package:equatable/equatable.dart';

/// Albüm ekranlarının olaylarının temel sınıfı.
sealed class AlbumEvent extends Equatable {
  const AlbumEvent();

  @override
  List<Object?> get props => [];
}

/// Albüm listesi açıldı.
final class AlbumStarted extends AlbumEvent {
  const AlbumStarted();
}

/// Kartlar veya coin'ler değişti (bir portal, bir ödül): yeniden yükle ve yeni sayfaları öde.
final class AlbumDataChanged extends AlbumEvent {
  const AlbumDataChanged();
}

/// Tek bir bölüm sayfası açıldı.
final class AlbumPageStarted extends AlbumEvent {
  const AlbumPageStarted();
}
