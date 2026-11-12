import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/storage/player_state.dart';

enum SettingsStatus { initial, success }

final class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings = const PlayerSettings(),
    this.demoUnlocked = false,
    this.legendaryArmed = false,
    this.coins = 0,
    this.demoUnlockedTick = 0,
    this.resetTick = 0,
    this.failure,
  });

  final SettingsStatus status;
  final PlayerSettings settings;
  final bool demoUnlocked;
  final bool legendaryArmed;
  final int coins;

  /// Increases when the demo panel unlocks (sound + haptic once).
  final int demoUnlockedTick;

  /// Increases after a progress reset (snack bar).
  final int resetTick;
  final Failure? failure;

  SettingsState copyWith({
    SettingsStatus? status,
    PlayerSettings? settings,
    bool? demoUnlocked,
    bool? legendaryArmed,
    int? coins,
    int? demoUnlockedTick,
    int? resetTick,
    Failure? failure,
  }) => SettingsState(
    status: status ?? this.status,
    settings: settings ?? this.settings,
    demoUnlocked: demoUnlocked ?? this.demoUnlocked,
    legendaryArmed: legendaryArmed ?? this.legendaryArmed,
    coins: coins ?? this.coins,
    demoUnlockedTick: demoUnlockedTick ?? this.demoUnlockedTick,
    resetTick: resetTick ?? this.resetTick,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    settings,
    demoUnlocked,
    legendaryArmed,
    coins,
    demoUnlockedTick,
    resetTick,
    failure,
  ];
}
