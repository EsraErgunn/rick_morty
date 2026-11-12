import 'package:equatable/equatable.dart';

import '../../../../core/storage/player_state.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

final class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

/// A toggle or a slider changed (applied and saved at once).
final class SettingsChanged extends SettingsEvent {
  const SettingsChanged(this.settings);

  final PlayerSettings settings;

  @override
  List<Object?> get props => [settings];
}

/// The version label was tapped at [at] (7 taps in 3 s unlock demo, D2).
final class VersionTapped extends SettingsEvent {
  const VersionTapped(this.at);

  final DateTime at;

  @override
  List<Object?> get props => [at];
}

final class DemoCoinsRequested extends SettingsEvent {
  const DemoCoinsRequested();
}

final class DemoLegendaryRequested extends SettingsEvent {
  const DemoLegendaryRequested();
}

/// "Demo modunu kapat".
final class DemoClosed extends SettingsEvent {
  const DemoClosed();
}

/// Confirmed in the destructive dialog.
final class ProgressResetConfirmed extends SettingsEvent {
  const ProgressResetConfirmed();
}
