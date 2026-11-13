import 'dart:math';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:portalcards/core/cards/game_card_data.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/core/game/battle_model.dart';
import 'package:portalcards/features/battle/domain/battle_repository.dart';
import 'package:portalcards/features/battle/presentation/bloc/battle_bloc.dart';
import 'package:portalcards/features/battle/presentation/bloc/battle_event.dart';
import 'package:portalcards/features/battle/presentation/bloc/battle_state.dart';

import '../../helpers/cards.dart';

class FakeBattleRepository implements BattleRepository {
  @override
  Stream<void> get changes => const Stream.empty();

  FakeBattleRepository({List<int> deck = const [1, 2, 23]})
    : _deck = [for (final id in deck) fixtureCard(id)];

  final List<GameCardData> _deck;
  final List<(String, BattleResult)> finished = [];
  BattleReward? _reward;

  @override
  List<GameCardData> deck() => _deck;

  @override
  int get wins => 4;

  @override
  int get tier => 1;

  @override
  List<GameCardData> opponents(Random random) => [
    for (final id in [71, 86, 82]) fixtureCard(id),
  ];

  @override
  Future<Either<Failure, BattleReward>> finish(
    String battleId,
    BattleResult result,
  ) async {
    if (_reward != null) return right(_reward!);
    finished.add((battleId, result));
    return right(
      _reward = BattleReward(
        result: result,
        coins: result == BattleResult.victory ? 125 : 25,
        coinsAfter: 500,
        wins: result == BattleResult.victory ? 5 : 4,
        tierBefore: 1,
        tierAfter: 1,
      ),
    );
  }
}

BattleBloc _bloc(FakeBattleRepository repo, {int seed = 7}) =>
    BattleBloc(repository: repo, random: Random(seed), newBattleId: () => 'b1');

/// Sıradaki her şeyi, sayfanın yaptığı gibi tekrar oynatır.
void _drain(BattleBloc bloc) {
  for (var i = 0; i < bloc.state.queue.length; i++) {
    bloc.add(const BattleReplayAdvanced());
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('BattleBloc', () {
    blocTest<BattleBloc, BattleViewState>(
      'opening shows the pre-battle screen with deck, opponent and tier',
      build: () => _bloc(FakeBattleRepository()),
      act: (b) => b.add(const BattleOpened()),
      expect: () => [
        isA<BattleViewState>()
            .having((s) => s.phase, 'phase', BattlePhase.preBattle)
            .having((s) => s.playerCards.length, 'deck', 3)
            .having((s) => s.enemyCards.map((c) => c.id), 'enemy', [71, 86, 82])
            .having((s) => s.tier, 'tier', 1),
      ],
    );

    blocTest<BattleBloc, BattleViewState>(
      'a deck with fewer than 3 cards cannot battle',
      build: () => _bloc(FakeBattleRepository(deck: [1, 2])),
      act: (b) => b.add(const BattleOpened()),
      expect: () => [
        isA<BattleViewState>().having(
          (s) => s.phase,
          'phase',
          BattlePhase.noDeck,
        ),
      ],
    );

    blocTest<BattleBloc, BattleViewState>(
      'Başla: the faster side (Rick, SPD 17) lets the player choose',
      build: () => _bloc(FakeBattleRepository()),
      act: (b) => b
        ..add(const BattleOpened())
        ..add(const BattleStartPressed()),
      skip: 1,
      expect: () => [
        isA<BattleViewState>()
            .having((s) => s.phase, 'phase', BattlePhase.choosing)
            .having((s) => s.view, 'view', isNotNull)
            .having((s) => s.inputBlocked, 'blocked', false),
      ],
    );

    blocTest<BattleBloc, BattleViewState>(
      'own card selects, tapping it again deselects; enemy first is ignored',
      build: () => _bloc(FakeBattleRepository()),
      act: (b) => b
        ..add(const BattleOpened())
        ..add(const BattleStartPressed())
        ..add(const BattleCardTapped(Side.enemy, 0))
        ..add(const BattleCardTapped(Side.player, 1))
        ..add(const BattleCardTapped(Side.player, 1)),
      skip: 2,
      expect: () => [
        isA<BattleViewState>().having((s) => s.selected, 'selected', 1),
        isA<BattleViewState>().having((s) => s.selected, 'selected', null),
      ],
    );

    test('a chosen attack queues the player turn, then the AI turn', () async {
      final bloc = _bloc(FakeBattleRepository())
        ..add(const BattleOpened())
        ..add(const BattleStartPressed())
        ..add(const BattleCardTapped(Side.player, 0))
        ..add(const BattleCardTapped(Side.enemy, 0));
      await _settle();
      final s = bloc.state;
      expect(s.phase, BattlePhase.replaying);
      expect(s.inputBlocked, isTrue);
      expect(s.queue.first, const TurnStarted(Side.player, 1));
      expect(s.queue[1], const Attacked(Side.player, 0, 0));
      expect(s.queue, contains(const TurnStarted(Side.enemy, 2)));
      // Tekrar oynatma ilerleyene kadar sahne hâlâ tam HP gösterir.
      expect(s.view!.enemy[0].hp, s.view!.enemy[0].maxHp);
      await bloc.close();
    });

    test('input is ignored while replaying', () async {
      final bloc = _bloc(FakeBattleRepository())
        ..add(const BattleOpened())
        ..add(const BattleStartPressed())
        ..add(const BattleCardTapped(Side.player, 0))
        ..add(const BattleCardTapped(Side.enemy, 0));
      await _settle();
      final before = bloc.state;
      bloc
        ..add(const BattleCardTapped(Side.player, 1))
        ..add(const BattleStartPressed());
      await _settle();
      expect(bloc.state, before);
      await bloc.close();
    });

    test(
      'the replay moves HP event by event and ends on the engine state',
      () async {
        final bloc = _bloc(FakeBattleRepository())
          ..add(const BattleOpened())
          ..add(const BattleStartPressed())
          ..add(const BattleCardTapped(Side.player, 0))
          ..add(const BattleCardTapped(Side.enemy, 0));
        await _settle();
        final events = bloc.state.queue;
        final damage = events.indexWhere((e) => e is Damaged);
        for (var i = 0; i <= damage; i++) {
          bloc.add(const BattleReplayAdvanced());
        }
        await _settle();
        final hit = events[damage] as Damaged;
        expect(bloc.state.view!.cards(hit.side)[hit.index].hp, hit.hpAfter);
        _drain(bloc);
        await _settle();
        expect(bloc.state.phase, BattlePhase.choosing);
        expect(bloc.state.view, bloc.state.battle);
        await bloc.close();
      },
    );

    test(
      'a full battle ends once, with the reward paid before the replay',
      () async {
        final repo = FakeBattleRepository();
        final bloc = _bloc(repo)
          ..add(const BattleOpened())
          ..add(const BattleStartPressed());
        await _settle();
        for (
          var turn = 0;
          turn < 40 && bloc.state.phase != BattlePhase.finished;
          turn++
        ) {
          if (bloc.state.phase == BattlePhase.choosing) {
            final b = bloc.state.battle!;
            final a = b.player.indexWhere((c) => c.alive);
            final t = b.enemy.indexWhere((c) => c.alive);
            bloc
              ..add(BattleCardTapped(Side.player, a))
              ..add(BattleCardTapped(Side.enemy, t));
            await _settle();
          }
          if (bloc.state.battle?.over ?? false) {
            expect(bloc.state.reward, isNotNull, reason: 'paid before replay');
            expect(bloc.state.queue.last, isA<BattleEnded>());
          }
          _drain(bloc);
          await _settle();
        }
        expect(bloc.state.phase, BattlePhase.finished);
        expect(repo.finished, hasLength(1));
        expect(repo.finished.single.$2, bloc.state.result);
        await bloc.close();
      },
    );

    test('leaving mid-battle counts as a defeat', () async {
      final repo = FakeBattleRepository();
      final bloc = _bloc(repo)
        ..add(const BattleOpened())
        ..add(const BattleStartPressed())
        ..add(const BattleLeft());
      await _settle();
      expect(bloc.state.phase, BattlePhase.finished);
      expect(bloc.state.left, isTrue);
      expect(bloc.state.result, BattleResult.defeat);
      expect(repo.finished, [('b1', BattleResult.defeat)]);
      await bloc.close();
    });

    blocTest<BattleBloc, BattleViewState>(
      '2× toggles',
      build: () => _bloc(FakeBattleRepository()),
      act: (b) => b
        ..add(const BattleSpeedToggled())
        ..add(const BattleSpeedToggled()),
      expect: () => [
        isA<BattleViewState>().having((s) => s.fast, 'fast', true),
        isA<BattleViewState>().having((s) => s.fast, 'fast', false),
      ],
    );
  });
}
