import 'package:equatable/equatable.dart';

import '../../../../core/storage/player_state.dart';

/// Ayarlar ekranının olaylarının temel sınıfı.
sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Ayarlar sayfası açıldı: kayıtlı ayarları yükle.
final class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

/// Bir anahtar ya da kaydırıcı değişti (hemen uygulanır ve kaydedilir).
final class SettingsChanged extends SettingsEvent {
  const SettingsChanged(this.settings);

  final PlayerSettings settings;

  @override
  List<Object?> get props => [settings];
}

/// Sürüm yazısına [at] anında dokunuldu (3 sn'de 7 dokunuş demoyu açar, D2).
final class VersionTapped extends SettingsEvent {
  const VersionTapped(this.at);

  final DateTime at;

  @override
  List<Object?> get props => [at];
}

/// Demo panelinde "+1000 coin" dokunuldu.
final class DemoCoinsRequested extends SettingsEvent {
  const DemoCoinsRequested();
}

/// Demo panelinde "Sonraki portal efsanevi" dokunuldu.
final class DemoLegendaryRequested extends SettingsEvent {
  const DemoLegendaryRequested();
}

/// "Demo modunu kapat".
final class DemoClosed extends SettingsEvent {
  const DemoClosed();
}

/// Yıkıcı işlem diyaloğunda onaylandı.
final class ProgressResetConfirmed extends SettingsEvent {
  const ProgressResetConfirmed();
}
