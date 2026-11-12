import 'package:equatable/equatable.dart';

import 'card_stats.dart';
import 'card_type.dart';
import 'featured.dart';
import 'passives.dart';

enum Side {
  player,
  enemy;

  Side get other => this == player ? enemy : player;
}

enum BattleResult { victory, defeat, draw }

/// One card in a battle with its live state [GM §6, §12].
final class BattleCard extends Equatable {
  const BattleCard({
    required this.id,
    required this.type,
    required this.passive,
    required this.maxHp,
    required this.atk,
    required this.def,
    required this.spd,
    required this.hp,
    this.signature,
    this.revived = false,
    this.signatureUsed = false,
    this.boosted = false,
    this.teamSpirit = false,
  });

  factory BattleCard.fromStats({
    required int id,
    required CardType type,
    required Passive passive,
    required CardStats stats,
    Signature? signature,
  }) => BattleCard(
    id: id,
    type: type,
    passive: passive,
    signature: signature,
    maxHp: stats.hp,
    atk: stats.atk,
    def: stats.def,
    spd: stats.spd,
    hp: stats.hp,
  );

  final int id;
  final CardType type;
  final Passive passive;
  final Signature? signature;
  final int maxHp;
  final int atk;
  final int def;
  final int spd;
  final int hp;

  /// Zombi used its revive.
  final bool revived;

  /// The once-per-battle signature already fired.
  final bool signatureUsed;

  /// Morty: next attack ×1.5.
  final bool boosted;

  /// Summer: ATK ×1.2 for the rest of the battle.
  final bool teamSpirit;

  bool get alive => hp > 0;

  BattleCard copyWith({
    int? hp,
    bool? revived,
    bool? signatureUsed,
    bool? boosted,
    bool? teamSpirit,
  }) => BattleCard(
    id: id,
    type: type,
    passive: passive,
    signature: signature,
    maxHp: maxHp,
    atk: atk,
    def: def,
    spd: spd,
    hp: hp ?? this.hp,
    revived: revived ?? this.revived,
    signatureUsed: signatureUsed ?? this.signatureUsed,
    boosted: boosted ?? this.boosted,
    teamSpirit: teamSpirit ?? this.teamSpirit,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    passive,
    signature,
    maxHp,
    atk,
    def,
    spd,
    hp,
    revived,
    signatureUsed,
    boosted,
    teamSpirit,
  ];
}

/// The whole battle at one moment. Immutable; the engine returns new ones.
final class BattleState extends Equatable {
  const BattleState({
    required this.player,
    required this.enemy,
    required this.active,
    this.turn = 0,
    this.result,
  });

  final List<BattleCard> player;
  final List<BattleCard> enemy;

  /// Whose move it is.
  final Side active;

  /// Turns played so far (one side's attack = one turn, Q1).
  final int turn;
  final BattleResult? result;

  bool get over => result != null;

  List<BattleCard> cards(Side side) => side == Side.player ? player : enemy;

  BattleState copyWith({
    List<BattleCard>? player,
    List<BattleCard>? enemy,
    Side? active,
    int? turn,
    BattleResult? result,
  }) => BattleState(
    player: player ?? this.player,
    enemy: enemy ?? this.enemy,
    active: active ?? this.active,
    turn: turn ?? this.turn,
    result: result ?? this.result,
  );

  @override
  List<Object?> get props => [player, enemy, active, turn, result];
}

/// What happened, in order; the UI replays these (architecture rules).
sealed class BattleEvent extends Equatable {
  const BattleEvent();

  @override
  List<Object?> get props => [];
}

final class TurnStarted extends BattleEvent {
  const TurnStarted(this.side, this.turn);

  final Side side;
  final int turn;

  @override
  List<Object?> get props => [side, turn];
}

final class Attacked extends BattleEvent {
  const Attacked(this.side, this.attacker, this.target);

  /// Side of the attacker; [attacker] and [target] are list indexes.
  final Side side;
  final int attacker;
  final int target;

  @override
  List<Object?> get props => [side, attacker, target];
}

/// Myth dodged (no damage).
final class Dodged extends BattleEvent {
  const Dodged(this.side, this.index);

  final Side side;
  final int index;

  @override
  List<Object?> get props => [side, index];
}

final class Damaged extends BattleEvent {
  const Damaged({
    required this.side,
    required this.index,
    required this.amount,
    required this.hpAfter,
    required this.isCrit,
    required this.effectiveness,
    this.signature,
  });

  /// Side and index of the card that took the damage.
  final Side side;
  final int index;
  final int amount;
  final int hpAfter;
  final bool isCrit;
  final Effectiveness effectiveness;

  /// Rick's crit: [Signature.genius] (UI shows "DAHİ!").
  final Signature? signature;

  @override
  List<Object?> get props => [
    side,
    index,
    amount,
    hpAfter,
    isCrit,
    effectiveness,
    signature,
  ];
}

final class Fainted extends BattleEvent {
  const Fainted(this.side, this.index);

  final Side side;
  final int index;

  @override
  List<Object?> get props => [side, index];
}

/// Zombi came back with [hp].
final class Revived extends BattleEvent {
  const Revived(this.side, this.index, this.hp);

  final Side side;
  final int index;
  final int hp;

  @override
  List<Object?> get props => [side, index, hp];
}

/// A featured signature fired [GM §12.2].
final class SignatureTriggered extends BattleEvent {
  const SignatureTriggered(this.side, this.index, this.signature);

  final Side side;
  final int index;
  final Signature signature;

  @override
  List<Object?> get props => [side, index, signature];
}

final class Healed extends BattleEvent {
  const Healed(this.side, this.index, this.amount, this.hpAfter);

  final Side side;
  final int index;
  final int amount;
  final int hpAfter;

  @override
  List<Object?> get props => [side, index, amount, hpAfter];
}

final class TurnEnded extends BattleEvent {
  const TurnEnded(this.side);

  final Side side;

  @override
  List<Object?> get props => [side];
}

final class BattleEnded extends BattleEvent {
  const BattleEnded(this.result);

  final BattleResult result;

  @override
  List<Object?> get props => [result];
}
