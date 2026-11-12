import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/portal_repository.dart';

/// idle → opening (repository saves) → revealing (scene plays) → revealed.
enum PortalPhase { idle, opening, revealing, revealed }

final class PortalState extends Equatable {
  const PortalState({
    this.phase = PortalPhase.idle,
    this.coins = 0,
    this.showShakeHint = false,
    this.result,
    this.notEnoughCoins = 0,
    this.failure,
  });

  final PortalPhase phase;
  final int coins;

  /// First visit only (SPEC D4); hidden once a portal opened.
  final bool showShakeHint;

  /// Set from `revealing` on; already saved.
  final PortalResult? result;

  /// Increases on every rejected open, so a listener can shake the coin
  /// counter each time (SPEC §2.3 AC2).
  final int notEnoughCoins;

  /// A storage problem while opening (the portal stays idle).
  final Failure? failure;

  /// Shake and button are ignored while not idle (SPEC §2.3 AC6).
  bool get busy => phase != PortalPhase.idle;

  PortalState copyWith({
    PortalPhase? phase,
    int? coins,
    bool? showShakeHint,
    PortalResult? result,
    int? notEnoughCoins,
    Failure? failure,
    bool clearResult = false,
    bool clearFailure = false,
  }) => PortalState(
    phase: phase ?? this.phase,
    coins: coins ?? this.coins,
    showShakeHint: showShakeHint ?? this.showShakeHint,
    result: clearResult ? null : result ?? this.result,
    notEnoughCoins: notEnoughCoins ?? this.notEnoughCoins,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    phase,
    coins,
    showShakeHint,
    result,
    notEnoughCoins,
    failure,
  ];
}
