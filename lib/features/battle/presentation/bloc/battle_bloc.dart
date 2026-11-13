import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cards/game_card_data.dart';
import '../../../../core/game/battle_engine.dart';
import '../../../../core/game/battle_model.dart';
import '../../domain/battle_repository.dart';
import 'battle_event.dart';
import 'battle_state.dart';

/// Tek bir savaş (SPEC §2.7); [BattleOpened] yenisini başlatır. Motor tüm turları tek seferde çözer;
/// sayfa sıradaki olayları tek tek tekrar oynatır ve her birine
/// [BattleReplayAdvanced] ile cevap verir. Girdi yalnızca [BattlePhase.choosing] durumunda kabul edilir.
class BattleBloc extends Bloc<BattleUiEvent, BattleViewState> {
  BattleBloc({
    required this._repository,
    required this._random,
    required this._newBattleId,
  }) : super(const BattleViewState()) {
    on<BattleOpened>(_onOpened);
    on<BattleStartPressed>(_onStart);
    on<BattleCardTapped>(_onCardTapped);
    on<BattleReplayAdvanced>(_onReplayAdvanced);
    on<BattleSpeedToggled>(
      (e, emit) => emit(state.copyWith(fast: !state.fast)),
    );
    on<BattleLeft>(_onLeft);
    on<BattleDeckChanged>(_onDeckChanged);
    _changes = _repository.changes.listen(
      (_) => add(const BattleDeckChanged()),
    );
  }

  final BattleRepository _repository;
  late final StreamSubscription<void> _changes;
  final Random _random;

  /// Her savaş için yeni bir id, böylece ödüller savaş başına bir kez ödenir.
  final String Function() _newBattleId;
  String _battleId = '';

  static const int teamSize = 3;

  void _onOpened(BattleOpened e, Emitter<BattleViewState> emit) {
    _battleId = _newBattleId();
    final deck = _repository.deck();
    final fresh = BattleViewState(fast: state.fast);
    if (deck.length < teamSize) {
      emit(fresh.copyWith(phase: BattlePhase.noDeck, playerCards: deck));
      return;
    }
    emit(
      fresh.copyWith(
        phase: BattlePhase.preBattle,
        playerCards: deck,
        enemyCards: _repository.opponents(_random),
        tier: _repository.tier,
        wins: _repository.wins,
      ),
    );
  }

  /// Savaştan önce: mevcut desteyi göster. Yeni dolan bir deste
  /// rakip alır; var olan rakip korunur. Savaş başladıktan sonra
  /// yok sayılır (savaşın kendi ödül yazımı da buraya düşer).
  void _onDeckChanged(BattleDeckChanged e, Emitter<BattleViewState> emit) {
    final phase = state.phase;
    if (phase != BattlePhase.noDeck && phase != BattlePhase.preBattle) return;
    final deck = _repository.deck();
    if (deck.length < teamSize) {
      emit(state.copyWith(phase: BattlePhase.noDeck, playerCards: deck));
    } else if (phase == BattlePhase.noDeck) {
      _onOpened(const BattleOpened(), emit);
    } else {
      emit(state.copyWith(playerCards: deck));
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
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
    // Ödüller sonuç animasyonundan önce yatırılır (AC5).
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

  /// Sahneyi bir olay ilerletir (HP ve tur; gerisi animasyon).
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
