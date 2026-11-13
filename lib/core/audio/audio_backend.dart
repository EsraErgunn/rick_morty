import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../logging/app_logger.dart';
import 'audio_assets.dart';

/// Çalan tek bir müzik parçası.
abstract interface class MusicHandle {
  Future<void> setVolume(double volume);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();

  /// Döngüsüz bir parça sonuna ulaşınca tamamlanır.
  Future<void> get completed;
}

/// Ses eklentisiyle konuşan tek yer (animasyon-ses kuralları:
/// widget'lar asla oynatıcı oluşturmaz). `AudioService`'e enjekte edilir, testlerde
/// sahtesi kullanılır.
abstract interface class AudioBackend {
  Future<void> preload(Iterable<Sfx> sounds);
  Future<void> playSfx(Sfx sound, double volume);

  /// [track] parçasını [volume] seviyesinde başlatır; parça döngülüyse döngüye girer.
  Future<MusicHandle> startMusic(Music track, double volume);
}

/// audioplayers uygulaması: her ses efekti için bir düşük gecikmeli havuz
/// (üst üste binebilir), her müzik parçası için bir medya oynatıcı.
class AudioplayersBackend implements AudioBackend {
  static const int _voicesPerSfx = 3;

  /// SFX, Android ses odağını almamalı: varsayılan bağlamda her
  /// efekt `AUDIOFOCUS_GAIN` istiyordu, döngüdeki müzik oynatıcısı
  /// kalıcı odak kaybı yaşıyor ve audioplayers onu tamamen duraklatıyordu (savaş
  /// müziği ilk dokunuşta duruyordu). Efektler artık müzikle karışır,
  /// odak müzikte kalır.
  static final AudioContext _sfxContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  final Map<Sfx, AudioPool> _pools = {};

  @override
  Future<void> preload(Iterable<Sfx> sounds) async {
    for (final sfx in sounds) {
      if (_pools.containsKey(sfx)) continue;
      try {
        _pools[sfx] = await AudioPool.create(
          source: AssetSource(sfx.asset),
          maxPlayers: _voicesPerSfx,
          playerMode: PlayerMode.lowLatency,
          audioContext: _sfxContext,
        );
      } on Object catch (e) {
        AppLogger.warning('sfx preload failed: ${sfx.file}', e);
      }
    }
  }

  @override
  Future<void> playSfx(Sfx sound, double volume) async {
    try {
      final pool =
          _pools[sound] ??
          (_pools[sound] = await AudioPool.create(
            source: AssetSource(sound.asset),
            maxPlayers: _voicesPerSfx,
            playerMode: PlayerMode.lowLatency,
            audioContext: _sfxContext,
          ));
      await pool.start(volume: volume);
    } on Object catch (e) {
      AppLogger.warning('sfx failed: ${sound.file}', e);
    }
  }

  @override
  Future<MusicHandle> startMusic(Music track, double volume) async {
    final player = AudioPlayer();
    final handle = _PlayerHandle(player);
    try {
      await player.setReleaseMode(
        track.loops ? ReleaseMode.loop : ReleaseMode.stop,
      );
      await player.setVolume(volume);
      await player.play(AssetSource(track.asset));
    } on Object catch (e) {
      AppLogger.warning('music failed: ${track.file}', e);
    }
    return handle;
  }
}

class _PlayerHandle implements MusicHandle {
  _PlayerHandle(this._player) {
    _sub = _player.onPlayerComplete.listen((_) {
      if (!_done.isCompleted) _done.complete();
    });
  }

  final AudioPlayer _player;
  final Completer<void> _done = Completer<void>();
  StreamSubscription<void>? _sub;

  @override
  Future<void> get completed => _done.future;

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    if (!_done.isCompleted) _done.complete();
    await _player.stop();
    await _player.dispose();
  }
}
