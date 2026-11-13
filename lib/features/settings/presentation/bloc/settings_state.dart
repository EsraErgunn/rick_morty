import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/storage/player_state.dart';

/// Ayarların yüklenme durumu.
enum SettingsStatus { initial, success }

/// Ayarlar ekranının durumu: ayarlar, demo modu ve coin.
final class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings = const PlayerSettings(),
    this.demoUnlocked = false,
    this.legendaryArmed = false,
    this.coins = 0,
    this.godMode = false,
    this.demoUnlockedTick = 0,
    this.resetTick = 0,
    this.failure,
  });

  final SettingsStatus status;
  final PlayerSettings settings;
  final bool demoUnlocked;
  final bool legendaryArmed;
  final int coins;

  /// God mode açık [GM §7.2].
  final bool godMode;

  /// Demo paneli açılınca artar (bir kez ses + titreşim).
  final int demoUnlockedTick;

  /// İlerleme sıfırlandıktan sonra artar (bilgi çubuğu).
  final int resetTick;
  final Failure? failure;

  SettingsState copyWith({
    SettingsStatus? status,
    PlayerSettings? settings,
    bool? demoUnlocked,
    bool? legendaryArmed,
    int? coins,
    bool? godMode,
    int? demoUnlockedTick,
    int? resetTick,
    Failure? failure,
  }) => SettingsState(
    status: status ?? this.status,
    settings: settings ?? this.settings,
    demoUnlocked: demoUnlocked ?? this.demoUnlocked,
    legendaryArmed: legendaryArmed ?? this.legendaryArmed,
    coins: coins ?? this.coins,
    godMode: godMode ?? this.godMode,
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
    godMode,
    coins,
    demoUnlockedTick,
    resetTick,
    failure,
  ];
}
