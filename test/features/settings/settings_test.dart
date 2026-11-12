import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:portalcards/app/app_info.dart';
import 'package:portalcards/core/audio/audio_assets.dart';
import 'package:portalcards/core/audio/audio_service.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/core/feedback/ui_feedback.dart';
import 'package:portalcards/core/haptics/haptics_service.dart';
import 'package:portalcards/core/storage/player_state.dart';
import 'package:portalcards/core/storage/player_store.dart';
import 'package:portalcards/features/settings/data/settings_repository_impl.dart';
import 'package:portalcards/features/settings/domain/settings_repository.dart';
import 'package:portalcards/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:portalcards/features/settings/presentation/bloc/settings_event.dart';
import 'package:portalcards/features/settings/presentation/bloc/settings_state.dart';
import 'package:portalcards/features/settings/presentation/pages/settings_page.dart';

import '../../core/storage/hive_test_helper.dart';
import '../../helpers/cards.dart';
import '../../helpers/fake_audio.dart';

/// In-memory repository (Hive I/O cannot run inside testWidgets).
class _MemorySettings implements SettingsRepository {
  @override
  PlayerSettings settings = const PlayerSettings();
  @override
  bool demoUnlocked = false;
  @override
  bool legendaryArmed = false;
  @override
  int coins = 300;
  int resets = 0;

  @override
  Future<Either<Failure, Unit>> saveSettings(PlayerSettings s) async {
    settings = s;
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> setDemoUnlocked(bool u) async {
    demoUnlocked = u;
    return right(unit);
  }

  @override
  Future<Either<Failure, int>> addDemoCoins() async => right(coins += 1000);

  @override
  Future<Either<Failure, Unit>> armLegendary() async {
    legendaryArmed = true;
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> resetProgress() async {
    resets++;
    coins = 300;
    return right(unit);
  }
}

void main() {
  test('AppInfo.version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final v = RegExp(
      r'^version: (\S+?)\+',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(v!.group(1), AppInfo.version);
  });

  group('repository (Hive)', () {
    useTempHive();

    test('demo coins go through Economy: +1000', () async {
      final repo = SettingsRepositoryImpl(
        player: await PlayerStore.open(),
        collection: await CollectionStore.open(),
      );
      expect((await repo.addDemoCoins()).getOrElse((_) => -1), 1300);
      expect(repo.coins, 1300);
    });

    test('reset keeps settings and sync data, clears the rest', () async {
      final player = await PlayerStore.open();
      final collection = await CollectionStore.open();
      await collection.addCopy(1, DateTime.utc(2026));
      await player.save(
        const PlayerState(
          coins: 5,
          deck: [1],
          portalsOpened: 9,
          shakeHintSeen: true,
          forceNextLegendary: true,
          settings: PlayerSettings(musicEnabled: false),
          syncVersion: 1,
          syncTotals: {'character': 826},
        ),
      );
      final repo = SettingsRepositoryImpl(
        player: player,
        collection: collection,
      );

      await repo.resetProgress();

      final s = player.state;
      expect(s.coins, 300);
      expect(s.deck, isEmpty);
      expect(s.portalsOpened, 0);
      expect(s.shakeHintSeen, isFalse);
      expect(s.forceNextLegendary, isFalse);
      expect(s.settings.musicEnabled, isFalse);
      expect(s.syncVersion, 1);
      expect(s.syncTotals, {'character': 826});
      expect(collection.ownedIds, isEmpty);
    });
  });

  group('bloc', () {
    final t0 = DateTime.utc(2026, 11, 12, 12);

    blocTest<SettingsBloc, SettingsState>(
      '7 taps within 3 s unlock the demo panel',
      build: () => SettingsBloc(_MemorySettings()),
      act: (b) {
        for (var i = 0; i < 7; i++) {
          b.add(VersionTapped(t0.add(Duration(milliseconds: 300 * i))));
        }
      },
      verify: (b) {
        expect(b.state.demoUnlocked, isTrue);
        expect(b.state.demoUnlockedTick, 1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      '6 taps, or 7 taps spread over more than 3 s, do not',
      build: () => SettingsBloc(_MemorySettings()),
      act: (b) {
        for (var i = 0; i < 7; i++) {
          b.add(VersionTapped(t0.add(Duration(milliseconds: 600 * i))));
        }
      },
      verify: (b) => expect(b.state.demoUnlocked, isFalse),
    );

    blocTest<SettingsBloc, SettingsState>(
      'demo actions: +1000, arm legendary, close',
      build: () => SettingsBloc(_MemorySettings()..demoUnlocked = true),
      act: (b) => b
        ..add(const SettingsStarted())
        ..add(const DemoCoinsRequested())
        ..add(const DemoLegendaryRequested())
        ..add(const DemoClosed()),
      verify: (b) {
        expect(b.state.coins, 1300);
        expect(b.state.legendaryArmed, isTrue);
        expect(b.state.demoUnlocked, isFalse);
      },
    );
  });

  group('page', () {
    late FakeBackend backend;
    late List<HapticKind> haptics;
    late _MemorySettings repo;

    Future<void> pumpPage(WidgetTester tester) async {
      backend = FakeBackend();
      haptics = [];
      repo = _MemorySettings();
      final audio = AudioService(backend: backend);
      final hap = HapticsService(driver: (k) async => haptics.add(k));
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        testApp(
          BlocProvider(
            create: (_) => SettingsBloc(repo)..add(const SettingsStarted()),
            child: SettingsPage(
              audio: audio,
              haptics: hap,
              feedback: UiFeedback(audio: audio, haptics: hap),
              version: AppInfo.version,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('turning sound off: saved, applied, and no tap sound', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.tap(find.byKey(const ValueKey('toggle-sound')));
      await frames(tester, const Duration(milliseconds: 300));
      expect(repo.settings.soundEnabled, isFalse);
      expect(backend.sfx, isEmpty);
      // Haptics are still on: the toggle still clicks.
      expect(haptics, contains(HapticKind.selection));
    });

    testWidgets('turning haptics off: no vibration for that toggle', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.tap(find.byKey(const ValueKey('toggle-haptics')));
      await frames(tester, const Duration(milliseconds: 300));
      expect(repo.settings.hapticsEnabled, isFalse);
      expect(haptics, isEmpty);
      expect(backend.sfx.map((e) => e.$1), contains(Sfx.buttonTap));
    });

    testWidgets('7 taps on the version open the demo panel with a sound', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('version-label')),
        200,
      );
      for (var i = 0; i < 7; i++) {
        await tester.tap(find.byKey(const ValueKey('version-label')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await frames(tester, const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('demo-panel')), findsOneWidget);
      expect(backend.sfx.map((e) => e.$1), contains(Sfx.portalOpen));
      expect(find.text('Sürüm 1.0.0'), findsOneWidget);
    });

    testWidgets('reset asks first; confirming resets and shows a message', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.tap(find.text('İlerlemeyi sıfırla'));
      await frames(tester, const Duration(milliseconds: 400));
      expect(find.text('İlerleme sıfırlansın mı?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('reset-confirm')));
      await frames(tester, const Duration(milliseconds: 400));
      expect(repo.resets, 1);
      expect(find.text('İlerleme sıfırlandı.'), findsOneWidget);
    });

    testWidgets('disclaimer and credits are shown', (tester) async {
      await pumpPage(tester);
      await tester.scrollUntilVisible(find.textContaining('hayran'), 200);
      expect(find.textContaining('ticari olmayan'), findsOneWidget);
      expect(find.textContaining('prosedürel'), findsOneWidget);
    });
  });
}
