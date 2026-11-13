import 'package:equatable/equatable.dart';

import '../../../../core/cards/game_card_data.dart';
import '../../../../core/game/battle_model.dart';
import '../../domain/battle_repository.dart';

/// Savaş ekranının aşaması.
enum BattlePhase {
  loading,

  /// Destede 3'ten az kart var.
  noDeck,
  preBattle,

  /// Oyuncunun saldıran + hedef seçmesi bekleniyor.
  choosing,

  /// Sayfa [BattleViewState.queue] kuyruğunu tekrar oynatıyor; girdi engelli.
  replaying,
  finished,
}

/// Savaş ekranının tüm durumu (değişmez).
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

  /// Motorun asıl durumu (sıradaki olayların zaten ötesinde).
  final BattleState? battle;

  /// Sahnenin gösterdiği: [queue] öncesindeki [battle], tekrar oynatmayla
  /// her seferinde bir olay ilerletilir.
  final BattleState? view;

  /// Henüz tekrar oynatılacak olaylar; sayfa [current] olayını canlandırır.
  final List<BattleEvent> queue;

  /// Her tekrar adımında artar, böylece art arda gelen eşit olaylar da
  /// sayfaya ulaşır.
  final int replayTick;

  /// Oyuncunun seçtiği saldıran indeksi.
  final int? selected;

  /// 2× tekrar oynatma hızı.
  final bool fast;

  /// Motor sonu bildirir bildirmez bir kez ödenir (AC5).
  final BattleReward? reward;
  final int tier;
  final int wins;

  /// Oyuncu savaşın ortasında çıktı (yenilgi sayıldı).
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
