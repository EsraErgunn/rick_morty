import 'package:equatable/equatable.dart';

/// Ana menünün olaylarının temel sınıfı.
sealed class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object?> get props => [];
}

/// Menü gösterildi (ya da başka bir ekrandan sonra yeniden gösterildi).
final class MenuStarted extends MenuEvent {
  const MenuStarted();
}

/// Kayıtlı veriler değişti (coin, kart, deste), bu ya da başka bir ekranda.
final class MenuDataChanged extends MenuEvent {
  const MenuDataChanged();
}
