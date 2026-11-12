import 'package:equatable/equatable.dart';

import '../../../../core/cards/game_card_data.dart';
import '../../../../core/game/battle_model.dart';
import '../../domain/battle_repository.dart';

enum BattlePhase {
  loading,

  /// The deck has fewer than 3 cards.
  noDeck,
  preBattle,

  /// Waiting for the player's attacker + target.
  choosing,

  /// The page is replaying [BattleViewState.queue]; input is blocked.
  replaying,
  finished,
}

final class BattleViewState extends Equatable {
  const BattleViewState({
    this.phase = BattlePhase.loading,
    this.playerCards = const [],
    this.enemyCards = const [],
    this.battle,
    this.view,
    this.queue = const [],
    this.replayTick = 0,
    this.selected,
    this.fast = false,
    this.reward,
    this.tier = 0,
    this.wins = 0,
    this.left = false,
  });

  final BattlePhase phase;
  final List<GameCardData> playerCards;
  final List<GameCardData> enemyCards;

  /// The engine's authoritative state (already past the queued events).
  final BattleState? battle;

  /// What the stage shows: [battle] before [queue], moved forward one event
  /// at a time by the replay.
  final BattleState? view;

  /// Events still to replay; the page animates [current].
  final List<BattleEvent> queue;

  /// Increases with every replay step, so equal consecutive events still
  /// reach the page.
  final int replayTick;

  /// The player's chosen attacker index.
  final int? selected;

  /// 2× replay speed.
  final bool fast;

  /// Paid once, as soon as the engine reports the end (AC5).
  final BattleReward? reward;
  final int tier;
  final int wins;

  /// The player left mid-battle (counted as a defeat).
  final bool left;

  BattleEvent? get current => queue.isEmpty ? null : queue.first;
  bool get inputBlocked => phase != BattlePhase.choosing;
  BattleResult? get result => battle?.result;

  BattleViewState copyWith({
    BattlePhase? phase,
    List<GameCardData>? playerCards,
    List<GameCardData>? enemyCards,
    BattleState? battle,
    BattleState? view,
    List<BattleEvent>? queue,
    int? replayTick,
    int? Function()? selected,
    bool? fast,
    BattleReward? reward,
    int? tier,
    int? wins,
    bool? left,
  }) => BattleViewState(
    phase: phase ?? this.phase,
    playerCards: playerCards ?? this.playerCards,
    enemyCards: enemyCards ?? this.enemyCards,
    battle: battle ?? this.battle,
    view: view ?? this.view,
    queue: queue ?? this.queue,
    replayTick: replayTick ?? this.replayTick,
    selected: selected == null ? this.selected : selected(),
    fast: fast ?? this.fast,
    reward: reward ?? this.reward,
    tier: tier ?? this.tier,
    wins: wins ?? this.wins,
    left: left ?? this.left,
  );

  @override
  List<Object?> get props => [
    phase,
    playerCards,
    enemyCards,
    battle,
    view,
    queue,
    replayTick,
    selected,
    fast,
    reward,
    tier,
    wins,
    left,
  ];
}
