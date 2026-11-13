import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/portal_repository.dart';

/// idle → opening (repository kaydeder) → revealing (sahne oynar) → revealed.
enum PortalPhase { idle, opening, revealing, revealed }

/// Portal ekranının durumu: aşama, coin, ipucu ve son sonuç.
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

  /// Yalnızca ilk ziyaret (SPEC D4); bir portal açılınca gizlenir.
  final bool showShakeHint;

  /// `revealing`'den itibaren dolu; zaten kaydedilmiş.
  final PortalResult? result;

  /// Her reddedilen açılışta artar, böylece bir dinleyici her seferinde coin
  /// sayacını sallayabilir (SPEC §2.3 AC2).
  final int notEnoughCoins;

  /// Açılış sırasında bir depolama sorunu (portal boşta kalır).
  final Failure? failure;

  /// Boşta değilken sallama ve buton yok sayılır (SPEC §2.3 AC6).
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
