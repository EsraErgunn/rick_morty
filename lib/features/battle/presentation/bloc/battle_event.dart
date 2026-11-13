import 'package:equatable/equatable.dart';

import '../../../../core/game/battle_model.dart';

sealed class BattleUiEvent extends Equatable {
  const BattleUiEvent();

  @override
  List<Object?> get props => [];
}

/// Load the deck and generate the opponent (pre-battle screen).
final class BattleOpened extends BattleUiEvent {
  const BattleOpened();
}

/// The stored deck changed. Applied only before the battle starts.
final class BattleDeckChanged extends BattleUiEvent {
  const BattleDeckChanged();
}

/// "Başla" on the pre-battle screen.
final class BattleStartPressed extends BattleUiEvent {
  const BattleStartPressed();
}

/// A card on the stage tapped: an own card selects the attacker, an enemy
/// card (with an attacker selected) is attacked.
final class BattleCardTapped extends BattleUiEvent {
  const BattleCardTapped(this.side, this.index);

  final Side side;
  final int index;

  @override
  List<Object?> get props => [side, index];
}

/// The page finished animating the current replay event.
final class BattleReplayAdvanced extends BattleUiEvent {
  const BattleReplayAdvanced();
}

final class BattleSpeedToggled extends BattleUiEvent {
  const BattleSpeedToggled();
}

/// Leaving confirmed in the dialog (SPEC §2.7 AC6): counts as a defeat.
final class BattleLeft extends BattleUiEvent {
  const BattleLeft();
}
