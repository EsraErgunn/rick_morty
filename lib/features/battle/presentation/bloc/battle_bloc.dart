import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cards/game_card_data.dart';
import '../../../../core/game/battle_engine.dart';
import '../../../../core/game/battle_model.dart';
import '../../domain/battle_repository.dart';
import 'battle_event.dart';
import 'battle_state.dart';

/// One battle (SPEC §2.7). The engine resolves whole turns at once; the
/// page replays the queued events one by one and answers each with
/// [BattleReplayAdvanced]. Input is accepted only in [BattlePhase.choosing].
class BattleBloc extends Bloc<BattleUiEvent, BattleViewState> {
  BattleBloc({
    required this._repository,
    required this._random,
    required this._battleId,
  }) : super(const BattleViewState()) {
    on<BattleOpened>(_onOpened);
    on<BattleStartPressed>(_onStart);
    on<BattleCardTapped>(_onCardTapped);
    on<BattleReplayAdvanced>(_onReplayAdvanced);
    on<BattleSpeedToggled>(
      (e, emit) => emit(state.copyWith(fast: !state.fast)),
    );
    on<BattleLeft>(_onLeft);
  }

  final BattleRepository _repository;
  final Random _random;
  final String _battleId;

  static const int teamSize = 3;

  void _onOpened(BattleOpened e, Emitter<BattleViewState> emit) {
    final deck = _repository.deck();
    if (deck.length < teamSize) {
      emit(state.copyWith(phase: BattlePhase.noDeck, playerCards: deck));
      return;
    }
    emit(
      state.copyWith(
        phase: BattlePhase.preBattle,
        playerCards: deck,
        enemyCards: _repository.opponents(_random),
        tier: _repository.tier,
        wins: _repository.wins,
      ),
    );
  }

  Future<void> _onStart(
    BattleStartPressed e,
    Emitter<BattleViewState> emit,
  ) async {
    if (state.phase != BattlePhase.preBattle) return;
    final start = BattleEngine.start(
      [for (final c in state.playerCards) _toBattle(c)],
      [for (final c in state.enemyCards) _toBattle(c)],
    );
    if (start.active == Side.player) {
      emit(
        state.copyWith(phase: BattlePhase.choosing, battle: start, view: start),
      );
      return;
    }
    final ai = BattleEngine.aiTurn(start, _random);
    await _enqueue(emit, before: start, after: ai.state, events: ai.events);
  }

  Future<void> _onCardTapped(
    BattleCardTapped e,
    Emitter<BattleViewState> emit,
  ) async {
    final battle = state.battle;
    if (state.phase != BattlePhase.choosing || battle == null) return;
    final cards = battle.cards(e.side);
    if (e.index < 0 || e.index >= cards.length || !cards[e.index].alive) {
      return;
    }
    if (e.side == Side.player) {
      final again = state.selected == e.index;
      emit(state.copyWith(selected: () => again ? null : e.index));
      return;
    }
    final attacker = state.selected;
    if (attacker == null) return;
    final step = BattleEngine.playerTurn(battle, attacker, e.index, _random);
    final BattleStep? turn = step.match((_) => null, (s) {
      if (s.state.over) return s;
      final ai = BattleEngine.aiTurn(s.state, _random);
      return (state: ai.state, events: [...s.events, ...ai.events]);
    });
    if (turn == null) return;
    await _enqueue(
      emit,
      before: battle,
      after: turn.state,
      events: turn.events,
    );
  }

  Future<void> _enqueue(
    Emitter<BattleViewState> emit, {
    required BattleState before,
    required BattleState after,
    required List<BattleEvent> events,
  }) async {
    // Rewards are credited before the result animation (AC5).
    var reward = state.reward;
    if (after.result case final result?) {
      reward = (await _repository.finish(_battleId, result)).toNullable();
    }
    emit(
      state.copyWith(
        phase: BattlePhase.replaying,
        battle: after,
        view: before,
        queue: events,
        replayTick: state.replayTick + 1,
        selected: () => null,
        reward: reward,
        wins: reward?.wins,
        tier: reward?.tierAfter,
      ),
    );
  }

  void _onReplayAdvanced(
    BattleReplayAdvanced e,
    Emitter<BattleViewState> emit,
  ) {
    if (state.phase != BattlePhase.replaying || state.queue.isEmpty) return;
    final rest = state.queue.sublist(1);
    final view = applyEvent(state.view!, state.queue.first);
    if (rest.isNotEmpty) {
      emit(
        state.copyWith(
          view: view,
          queue: rest,
          replayTick: state.replayTick + 1,
        ),
      );
      return;
    }
    final battle = state.battle!;
    emit(
      state.copyWith(
        phase: battle.over ? BattlePhase.finished : BattlePhase.choosing,
        view: battle,
        queue: const [],
        replayTick: state.replayTick + 1,
      ),
    );
  }

  Future<void> _onLeft(BattleLeft e, Emitter<BattleViewState> emit) async {
    final playing =
        state.phase == BattlePhase.choosing ||
        state.phase == BattlePhase.replaying;
    if (!playing) return;
    final reward = (await _repository.finish(
      _battleId,
      BattleResult.defeat,
    )).toNullable();
    emit(
      state.copyWith(
        phase: BattlePhase.finished,
        queue: const [],
        reward: reward,
        wins: reward?.wins,
        tier: reward?.tierAfter,
        left: true,
        battle: state.battle?.copyWith(result: BattleResult.defeat),
      ),
    );
  }

  static BattleCard _toBattle(GameCardData c) => BattleCard.fromStats(
    id: c.id,
    type: c.type,
    passive: c.passive,
    stats: c.stats,
    signature: c.signature,
  );

  /// Moves the stage one event forward (HP and turn; the rest is animation).
  static BattleState applyEvent(BattleState view, BattleEvent event) {
    BattleState setHp(Side side, int index, int hp) {
      final cards = [...view.cards(side)];
      cards[index] = cards[index].copyWith(hp: hp);
      return side == Side.player
          ? view.copyWith(player: cards)
          : view.copyWith(enemy: cards);
    }

    return switch (event) {
      Damaged(:final side, :final index, :final hpAfter) => setHp(
        side,
        index,
        hpAfter,
      ),
      Healed(:final side, :final index, :final hpAfter) => setHp(
        side,
        index,
        hpAfter,
      ),
      Revived(:final side, :final index, :final hp) => setHp(side, index, hp),
      TurnStarted(:final side, :final turn) => view.copyWith(
        active: side,
        turn: turn,
      ),
      _ => view,
    };
  }
}
