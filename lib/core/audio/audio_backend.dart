import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../logging/app_logger.dart';
import 'audio_assets.dart';

/// One playing music track.
abstract interface class MusicHandle {
  Future<void> setVolume(double volume);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();

  /// Completes when a non-looping track reaches its end.
  Future<void> get completed;
}

/// The only place that talks to the audio plugin (animation-audio rules:
/// widgets never create players). Injected into `AudioService`, faked in
/// tests.
abstract interface class AudioBackend {
  Future<void> preload(Iterable<Sfx> sounds);
  Future<void> playSfx(Sfx sound, double volume);

  /// Starts [track] at [volume]; loops if the track loops.
  Future<MusicHandle> startMusic(Music track, double volume);
}

/// audioplayers implementation: one low-latency pool per sound effect
/// (overlap allowed), one media player per music track.
class AudioplayersBackend implements AudioBackend {
  static const int _voicesPerSfx = 3;

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
