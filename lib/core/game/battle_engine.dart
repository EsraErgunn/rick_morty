import 'dart:math';

import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';
import 'battle_ai.dart';
import 'battle_model.dart';
import 'card_type.dart';
import 'featured.dart';
import 'passives.dart';

/// State after a turn and what happened during it.
typedef BattleStep = ({BattleState state, List<BattleEvent> events});

/// 3 vs 3 turn-based battle [GM §6] with passives [GM §5], type traits
/// [GM §3] and featured signatures [GM §12.2]. Pure and deterministic:
/// the same state, choices and seed give the same events. Never waits for
/// the UI.
abstract final class BattleEngine {
  /// Turn limit: one side's attack is one turn (decision Q1).
  static const int maxTurns = 40;

  static const double baseCritChance = 0.10;
  static const double critMultiplier = 1.5;
  static const double mythDodgeChance = 0.10;
  static const double defenseScale = 50;

  /// Who starts: the side whose fastest alive card is faster; a Beast
  /// counts as infinitely fast for its side's first turn; tie → player.
  static BattleState start(List<BattleCard> player, List<BattleCard> enemy) {
    double speed(List<BattleCard> side) =>
        side.any((c) => c.alive && c.type == CardType.beast)
        ? double.infinity
        : side.where((c) => c.alive).map((c) => c.spd.toDouble()).fold(0, max);
    final first = speed(enemy) > speed(player) ? Side.enemy : Side.player;
    return BattleState(player: player, enemy: enemy, active: first);
  }

  static Either<Failure, BattleStep> playerTurn(
    BattleState state,
    int attacker,
    int target,
    Random random,
  ) {
    if (state.over || state.active != Side.player) {
      return left(const InvalidMoveFailure('not your turn'));
    }
    if (!_valid(state.player, attacker) || !_valid(state.enemy, target)) {
      return left(const InvalidMoveFailure('fainted or missing card'));
    }
    return right(_resolve(state, Side.player, attacker, target, random));
  }

  /// The AI's turn for whichever side is active (used for the enemy, and
  /// for both sides in the balance simulation).
  static BattleStep aiTurn(BattleState state, Random random) {
    final (a, t) = BattleAi.choose(state, state.active);
    return _resolve(state, state.active, a, t, random);
  }

  static bool _valid(List<BattleCard> side, int i) =>
      i >= 0 && i < side.length && side[i].alive;

  static BattleStep _resolve(
    BattleState state,
    Side side,
    int a,
    int t,
    Random random,
  ) {
    final own = [...state.cards(side)];
    final foe = [...state.cards(side.other)];
    final turn = state.turn + 1;
    final events = <BattleEvent>[TurnStarted(side, turn), Attacked(side, a, t)];
    var attacker = own[a];
    var defender = foe[t];

    if (defender.type == CardType.myth &&
        random.nextDouble() < mythDodgeChance) {
      events.add(Dodged(side.other, t));
    } else {
      final critChance = attacker.signature == Signature.genius
          ? SignatureRules.geniusCritChance
          : baseCritChance;
      final isCrit = random.nextDouble() < critChance;
      final eff = Effectiveness.of(attacker.type, defender.type);
      final passive = Passives.attackMultiplier(attacker.passive, random);
      var signature = 1.0;
      if (attacker.boosted) {
        signature *= SignatureRules.awJeezMultiplier;
        attacker = attacker.copyWith(boosted: false);
      }
      if (defender.signature == Signature.pickleArmor &&
          !defender.signatureUsed) {
        signature *= SignatureRules.pickleArmorMultiplier;
        defender = defender.copyWith(signatureUsed: true);
        events.add(SignatureTriggered(side.other, t, Signature.pickleArmor));
      }
      final atk =
          attacker.atk *
          (attacker.teamSpirit ? SignatureRules.teamSpiritAtkMultiplier : 1);
      final amount = max(
        1,
        (atk *
                eff.multiplier *
                (isCrit ? critMultiplier : 1) *
                passive *
                signature *
                defenseScale /
                (defenseScale + defender.def))
            .round(),
      );
      final hpAfter = max(0, defender.hp - amount);
      defender = defender.copyWith(hp: hpAfter);
      events.add(
        Damaged(
          side: side.other,
          index: t,
          amount: amount,
          hpAfter: hpAfter,
          isCrit: isCrit,
          effectiveness: eff,
          signature: isCrit && attacker.signature == Signature.genius
              ? Signature.genius
              : null,
        ),
      );

      if (defender.alive &&
          defender.signature == Signature.awJeez &&
          !defender.signatureUsed &&
          defender.hp <= defender.maxHp * SignatureRules.awJeezHpFraction) {
        defender = defender.copyWith(boosted: true, signatureUsed: true);
        events.add(SignatureTriggered(side.other, t, Signature.awJeez));
      }

      if (!defender.alive) {
        events.add(Fainted(side.other, t));
        if (attacker.signature == Signature.missionComplete &&
            !attacker.signatureUsed) {
          final heal =
              (attacker.maxHp * SignatureRules.missionCompleteHealFraction)
                  .round();
          final hp = min(attacker.maxHp, attacker.hp + heal);
          events
            ..add(SignatureTriggered(side, a, Signature.missionComplete))
            ..add(Healed(side, a, hp - attacker.hp, hp));
          attacker = attacker.copyWith(hp: hp, signatureUsed: true);
        }
        if (defender.passive == Passive.zombie && !defender.revived) {
          final hp = Passives.zombieReviveHp(defender.maxHp);
          defender = defender.copyWith(hp: hp, revived: true);
          events.add(Revived(side.other, t, hp));
        } else {
          for (var i = 0; i < foe.length; i++) {
            final ally = foe[i];
            if (i != t &&
                ally.alive &&
                ally.signature == Signature.teamSpirit &&
                !ally.signatureUsed) {
              foe[i] = ally.copyWith(teamSpirit: true, signatureUsed: true);
              events.add(
                SignatureTriggered(side.other, i, Signature.teamSpirit),
              );
            }
          }
        }
      }
    }

    own[a] = attacker;
    foe[t] = defender;
    events.add(TurnEnded(side));

    final playerCards = side == Side.player ? own : foe;
    final enemyCards = side == Side.player ? foe : own;
    BattleResult? result;
    if (!enemyCards.any((c) => c.alive)) {
      result = BattleResult.victory;
    } else if (!playerCards.any((c) => c.alive)) {
      result = BattleResult.defeat;
    } else if (turn >= maxTurns) {
      result = BattleResult.draw;
    }
    if (result != null) events.add(BattleEnded(result));

    return (
      state: BattleState(
        player: List.unmodifiable(playerCards),
        enemy: List.unmodifiable(enemyCards),
        active: side.other,
        turn: turn,
        result: result,
      ),
      events: events,
    );
  }
}
