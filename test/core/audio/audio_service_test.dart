import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/audio/audio_assets.dart';
import 'package:portalcards/core/audio/audio_service.dart';
import 'package:portalcards/core/storage/player_state.dart';

import '../../helpers/fake_audio.dart';

const _fade = AudioService.crossfade;

void main() {
  late FakeBackend backend;
  late AudioService audio;

  setUp(() {
    backend = FakeBackend();
    audio = AudioService(backend: backend);
  });

  test('every asset in the enums exists on disk', () {
    for (final s in Sfx.values) {
      expect(File('assets/${s.asset}').existsSync(), isTrue, reason: s.asset);
    }
    for (final m in Music.values) {
      expect(File('assets/${m.asset}').existsSync(), isTrue, reason: m.asset);
    }
  });

  test('preload loads every sound effect', () async {
    await audio.preload();
    expect(backend.preloaded, Sfx.values.toSet());
  });

  group('sfx', () {
    test('plays at the sfx volume', () async {
      await audio.applySettings(const PlayerSettings(sfxVolume: 0.5));
      await audio.play(Sfx.coin);
      expect(backend.sfx, [(Sfx.coin, 0.5)]);
    });

    test('sound off or volume 0: no player call', () async {
      await audio.applySettings(const PlayerSettings(soundEnabled: false));
      await audio.play(Sfx.hit);
      await audio.applySettings(const PlayerSettings(sfxVolume: 0));
      await audio.play(Sfx.hit);
      expect(backend.sfx, isEmpty);
    });
  });

  group('music', () {
    testWidgets('menu fades in to the music volume', (tester) async {
      await audio.applySettings(const PlayerSettings(musicVolume: 0.8));
      unawaited(audio.playMusic(Music.menuLoop));
      await tester.pump();
      expect(backend.music.single.volume, 0);
      await tester.pump(_fade ~/ 2);
      expect(backend.music.single.volume, closeTo(0.4, 0.06));
      await tester.pump(_fade);
      expect(backend.music.single.volume, 0.8);
      expect(audio.currentMusic, Music.menuLoop);
    });

    testWidgets('menu -> battle crossfades and stops the old track', (
      tester,
    ) async {
      unawaited(audio.playMusic(Music.menuLoop));
      await tester.pump(_fade * 2);
      unawaited(audio.playMusic(Music.battleLoop));
      await tester.pump(_fade ~/ 2);
      final menu = backend.music[0];
      final battle = backend.music[1];
      expect(menu.volume, lessThan(1));
      expect(battle.volume, greaterThan(0));
      await tester.pump(_fade * 2);
      expect(menu.stopped, isTrue);
      expect(backend.live.single.track, Music.battleLoop);
    });

    testWidgets('same track again does not restart it', (tester) async {
      unawaited(audio.playMusic(Music.menuLoop));
      await tester.pump(_fade * 2);
      unawaited(audio.playMusic(Music.menuLoop));
      await tester.pump(_fade * 2);
      expect(backend.music, hasLength(1));
    });

    testWidgets('sting plays once, then the last loop returns', (tester) async {
      unawaited(audio.playMusic(Music.menuLoop));
      await tester.pump(_fade * 2);
      unawaited(audio.playSting());
      await tester.pump(_fade * 2);
      expect(audio.currentMusic, Music.legendarySting);

      backend.music.last.done.complete(); // sting sonuna ulaştı
      await tester.pump();
      await tester.pump(_fade * 2);
      expect(audio.currentMusic, Music.menuLoop);
      expect(backend.live.single.track, Music.menuLoop);
    });

    testWidgets('music off: nothing starts; on again: the wanted loop starts', (
      tester,
    ) async {
      await audio.applySettings(const PlayerSettings(musicEnabled: false));
      unawaited(audio.playMusic(Music.menuLoop));
      await tester.pump(_fade * 2);
      expect(backend.music, isEmpty);

      unawaited(audio.applySettings(const PlayerSettings()));
      await tester.pump(_fade * 2);
      expect(audio.currentMusic, Music.menuLoop);
    });

    testWidgets('turning music off fades out and stops the track', (
      tester,
    ) async {
      unawaited(audio.playMusic(Music.battleLoop));
      await tester.pump(_fade * 2);
      unawaited(audio.applySettings(const PlayerSettings(musicEnabled: false)));
      await tester.pump(_fade * 2);
      expect(backend.music.single.stopped, isTrue);
      expect(audio.currentMusic, isNull);
    });

    testWidgets('volume change applies to the playing track at once', (
      tester,
    ) async {
      unawaited(audio.playMusic(Music.menuLoop));
      await tester.pump(_fade * 2);
      await audio.applySettings(const PlayerSettings(musicVolume: 0.3));
      expect(backend.music.single.volume, 0.3);
    });

    testWidgets('background pauses music, resume continues it', (tester) async {
      unawaited(audio.playMusic(Music.menuLoop));
      await tester.pump(_fade * 2);
      audio.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(backend.music.single.paused, isTrue);
      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(backend.music.single.paused, isFalse);
    });
  });
}
