import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/theme/colors.dart';
import 'package:portalcards/core/audio/audio_assets.dart';
import 'package:portalcards/core/audio/audio_service.dart';
import 'package:portalcards/core/game/battle_model.dart';
import 'package:portalcards/core/game/card_type.dart';
import 'package:portalcards/core/game/featured.dart';
import 'package:portalcards/core/haptics/haptics_service.dart';
import 'package:portalcards/core/widgets/game_card/card_art.dart';
import 'package:portalcards/features/battle/presentation/battle_feedback.dart';
import 'package:portalcards/features/battle/presentation/bloc/battle_bloc.dart';
import 'package:portalcards/features/battle/presentation/bloc/battle_event.dart';
import 'package:portalcards/features/battle/presentation/bloc/battle_state.dart';
import 'package:portalcards/features/battle/presentation/pages/battle_page.dart';
import 'package:portalcards/features/battle/presentation/widgets/battle_card_slot.dart';
import 'package:portalcards/features/battle/presentation/widgets/battle_cues.dart';
import 'package:portalcards/features/battle/presentation/widgets/hp_bar.dart';
import 'package:portalcards/l10n/app_localizations.dart';

import '../../helpers/cards.dart';
import '../../helpers/fake_audio.dart';
import 'battle_bloc_test.dart' show FakeBattleRepository;

void main() {
  late FakeBackend backend;
  late BattleFeedback feedback;
  late List<HapticKind> haptics;
  late int exits;

  setUp(() {
    backend = FakeBackend();
    haptics = [];
    exits = 0;
    feedback = BattleFeedback(
      audio: AudioService(backend: backend),
      haptics: HapticsService(driver: (k) async => haptics.add(k)),
    );
    CardArt.debugArtBuilder = testArt;
  });
  tearDown(() => CardArt.debugArtBuilder = null);

  Future<(BattleBloc, FakeBattleRepository)> pump(
    WidgetTester tester, {
    bool reduceMotion = false,
    int seed = 7,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = FakeBattleRepository();
    final bloc = BattleBloc(
      repository: repo,
      random: Random(seed),
      newBattleId: () => 'b1',
    )..add(const BattleOpened());
    await tester.pumpWidget(
      testApp(
        BlocProvider.value(
          value: bloc,
          child: BattlePage(
            feedback: feedback,
            onExit: () => exits++,
            onGoToDeck: () {},
          ),
        ),
        reduceMotion: reduceMotion,
      ),
    );
    await frames(tester, const Duration(milliseconds: 500));
    return (bloc, repo);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await frames(tester, const Duration(seconds: 2));
  }

  /// Plays until the result screen: first alive attacker on first alive
  /// enemy, replaying everything in between.
  Future<void> playOut(WidgetTester tester, BattleBloc bloc) async {
    for (var i = 0; i < 60 && bloc.state.phase != BattlePhase.finished; i++) {
      if (bloc.state.phase == BattlePhase.choosing) {
        final b = bloc.state.battle!;
        await tester.tap(
          find.byKey(ValueKey('player-${b.player.indexWhere((c) => c.alive)}')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(ValueKey('enemy-${b.enemy.indexWhere((c) => c.alive)}')),
        );
      }
      await frames(tester, const Duration(seconds: 3));
    }
  }

  testWidgets('pre-battle shows tier and Başla; battle music starts', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Kademe 1 · 4 galibiyet'), findsOneWidget);
    expect(find.text('Rakip'), findsOneWidget);
    expect(backend.live.single.track, Music.battleLoop);
    await tester.tap(find.byKey(const ValueKey('battle-start')));
    await frames(tester, const Duration(milliseconds: 600));
    expect(find.text('Senin sıran: saldıracak kartı seç'), findsOneWidget);
    await unmount(tester);
    expect(backend.live.single.track, Music.menuLoop);
  });

  testWidgets('select lifts the attacker and outlines alive enemies', (
    tester,
  ) async {
    final (bloc, _) = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('battle-start')));
    await frames(tester, const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const ValueKey('player-0')));
    await frames(tester, const Duration(milliseconds: 200));
    expect(bloc.state.selected, 0);
    expect(find.text('Hedefi seç'), findsOneWidget);
    final slots = tester.widgetList<BattleCardSlot>(
      find.byType(BattleCardSlot),
    );
    expect(slots.where((s) => s.targetable), hasLength(3));
    expect(slots.where((s) => s.selected).single.side, Side.player);
    expect(backend.sfx.last.$1, Sfx.buttonTap);
    await unmount(tester);
  });

  testWidgets('an attack replays both turns, then input opens again', (
    tester,
  ) async {
    final (bloc, _) = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('battle-start')));
    await frames(tester, const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const ValueKey('player-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('enemy-0')));
    await tester.pump();
    expect(bloc.state.phase, BattlePhase.replaying);
    expect(find.text('-'), findsNothing);

    // Input is blocked mid-replay.
    final queued = bloc.state.queue.length;
    await tester.tap(find.byKey(const ValueKey('player-1')));
    await tester.pump();
    expect(bloc.state.selected, isNull);

    // Two turns stay within 2 × 1.6 s.
    await frames(tester, const Duration(milliseconds: 3200));
    expect(bloc.state.phase, BattlePhase.choosing);
    expect(queued, greaterThan(4));
    final sfx = backend.sfx.map((e) => e.$1).toSet();
    expect(
      sfx.intersection({
        Sfx.hit,
        Sfx.critHit,
        Sfx.superEffective,
        Sfx.geniusCrit,
      }),
      isNotEmpty,
    );
    expect(bloc.state.view, bloc.state.battle);
    await unmount(tester);
  });

  testWidgets('a whole battle ends on the result screen with the reward', (
    tester,
  ) async {
    final (bloc, repo) = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('battle-start')));
    await frames(tester, const Duration(milliseconds: 600));
    await playOut(tester, bloc);
    expect(bloc.state.phase, BattlePhase.finished);
    expect(find.byKey(const ValueKey('battle-result')), findsOneWidget);
    expect(repo.finished, hasLength(1));
    final coins = bloc.state.reward!.coins;
    expect(find.text('+$coins coin'), findsOneWidget);
    expect(backend.live, isEmpty, reason: 'music stops on the result');
    await unmount(tester);
  });

  testWidgets('reduced motion still replays to the end', (tester) async {
    final (bloc, _) = await pump(tester, reduceMotion: true);
    await tester.tap(find.byKey(const ValueKey('battle-start')));
    await frames(tester, const Duration(milliseconds: 300));
    await playOut(tester, bloc);
    expect(bloc.state.phase, BattlePhase.finished);
    await unmount(tester);
  });

  testWidgets('leaving asks first and counts as a defeat', (tester) async {
    final (_, repo) = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('battle-start')));
    await frames(tester, const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const ValueKey('battle-leave')));
    await frames(tester, const Duration(milliseconds: 400));
    expect(find.text('Savaştan çıkılsın mı?'), findsOneWidget);
    expect(find.text('Bu savaş yenilgi sayılır.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('battle-leave-confirm')));
    await frames(tester, const Duration(milliseconds: 400));
    expect(repo.finished, [('b1', BattleResult.defeat)]);
    expect(exits, 1);
    await unmount(tester);
  });

  group('cues (SPEC §4.7)', () {
    final l10n = lookupAppLocalizations(const Locale('tr'));

    Damaged hit({
      bool crit = false,
      Effectiveness eff = Effectiveness.normal,
      Signature? sig,
    }) => Damaged(
      side: Side.enemy,
      index: 1,
      amount: 30,
      hpAfter: 50,
      isCrit: crit,
      effectiveness: eff,
      signature: sig,
    );

    test('damage shakes the target and floats the number', () {
      final cue = BattleCues.of(hit(), l10n);
      final slot = cue.slots[(Side.enemy, 1)]!;
      expect(slot.motion, SlotMotion.shake);
      expect(slot.popup!.text, '-30');
      expect(cue.band, isNull);
    });

    test('callouts: KRİTİK!, DAHİ!, SÜPER ETKİLİ!, Pek etkili değil…', () {
      expect(BattleCues.of(hit(crit: true), l10n).band!.text, 'KRİTİK!');
      expect(
        BattleCues.of(hit(crit: true, sig: Signature.genius), l10n).band!.text,
        'DAHİ!',
      );
      final sup = BattleCues.of(hit(eff: Effectiveness.superEffective), l10n);
      expect(sup.band!.text, 'SÜPER ETKİLİ!');
      expect(sup.band!.elastic, isTrue);
      final weak = BattleCues.of(
        hit(eff: Effectiveness.notVeryEffective),
        l10n,
      );
      expect(weak.band!.text, 'Pek etkili değil…');
      expect(weak.band!.small, isTrue);
    });

    test('dodge, revive, attack, heal and signatures', () {
      expect(
        BattleCues.of(const Dodged(Side.enemy, 0), l10n).band!.text,
        'KAÇTI!',
      );
      expect(
        BattleCues.of(
          const Revived(Side.player, 2, 40),
          l10n,
        ).slots[(Side.player, 2)]!.motion,
        SlotMotion.revive,
      );
      expect(
        BattleCues.of(
          const Attacked(Side.player, 1, 0),
          l10n,
        ).slots[(Side.player, 1)]!.motion,
        SlotMotion.lunge,
      );
      expect(
        BattleCues.of(
          const Healed(Side.player, 0, 12, 90),
          l10n,
        ).slots[(Side.player, 0)]!.popup!.text,
        '+12',
      );
      expect(
        BattleCues.of(
          const SignatureTriggered(Side.player, 0, Signature.missionComplete),
          l10n,
        ).band!.text,
        'Görev tamam!',
      );
    });

    test('one turn (start, attack, damage, end) stays ≤ 1.6 s', () {
      final total = [
        const TurnStarted(Side.player, 1),
        const Attacked(Side.player, 0, 0),
        hit(),
        const TurnEnded(Side.player),
      ].map((e) => BattleCues.of(e, l10n).duration).reduce((a, b) => a + b);
      expect(total.inMilliseconds, lessThanOrEqualTo(1600));
    });
  });

  group('HpBar', () {
    testWidgets('the fill is visible: full HP fills the bar', (tester) async {
      await tester.pumpWidget(
        testApp(
          const Center(
            child: SizedBox(width: 100, child: HpBar(hp: 50, maxHp: 50)),
          ),
        ),
      );
      final fill = find.descendant(
        of: find.byType(FractionallySizedBox),
        matching: find.byType(DecoratedBox),
      );
      final size = tester.getSize(fill.first);
      expect(size.height, greaterThan(0));
      expect(size.width, greaterThan(90));
    });

    test('portal green, yellow ≤ 50 %, red ≤ 20 %', () {
      expect(HpBar.colorFor(0.8), AppColors.portal);
      expect(HpBar.colorFor(0.5), AppColors.warn);
      expect(HpBar.colorFor(0.2), AppColors.danger);
    });
  });

  group('BattleFeedback', () {
    test('crit by Rick plays genius_crit, normal hit plays hit', () {
      feedback.event(
        const Damaged(
          side: Side.enemy,
          index: 0,
          amount: 50,
          hpAfter: 10,
          isCrit: true,
          effectiveness: Effectiveness.normal,
          signature: Signature.genius,
        ),
      );
      feedback.event(
        const Damaged(
          side: Side.enemy,
          index: 0,
          amount: 5,
          hpAfter: 5,
          isCrit: false,
          effectiveness: Effectiveness.normal,
        ),
      );
      expect(backend.sfx.map((e) => e.$1), [Sfx.geniusCrit, Sfx.hit]);
    });
  });
}
