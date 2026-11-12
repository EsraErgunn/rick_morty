import 'dart:async';

import 'package:flutter/widgets.dart';

import '../storage/player_state.dart';
import 'audio_assets.dart';
import 'audio_backend.dart';

/// All sound in the app goes through here (animation-audio rules).
///
/// - SFX: preloaded pool, overlap allowed, respects `soundEnabled` and
///   `sfxVolume`.
/// - Music: one track at a time, crossfades between tracks, respects
///   `musicEnabled` and `musicVolume`, pauses in the background.
/// - [playSting] plays a one-shot track, then returns to the loop that was
///   asked for last (legendary reveal, SPEC §4.3).
class AudioService with WidgetsBindingObserver {
  AudioService({
    required this._backend,
    this._settings = const PlayerSettings(),
  });

  /// Music crossfade length (not a visual token: audio timing).
  static const Duration crossfade = Duration(milliseconds: 800);
  static const int _fadeSteps = 16;

  final AudioBackend _backend;
  PlayerSettings _settings;

  _Playing? _current;
  Music? _desired;
  int _generation = 0;
  bool _inBackground = false;

  PlayerSettings get settings => _settings;

  /// The track playing now (null if silent).
  Music? get currentMusic => _current?.track;

  /// Loads every sound effect (call once at startup).
  Future<void> preload() => _backend.preload(Sfx.values);

  /// Registers for app lifecycle events (background pause).
  void attachLifecycle() => WidgetsBinding.instance.addObserver(this);

  void detachLifecycle() => WidgetsBinding.instance.removeObserver(this);

  Future<void> play(Sfx sound) async {
    if (!_settings.soundEnabled || _settings.sfxVolume <= 0) return;
    await _backend.playSfx(sound, _settings.sfxVolume);
  }

  /// Plays [track] as the background loop (crossfade from the current one).
  Future<void> playMusic(Music track) async {
    _desired = track;
    if (!_musicOn || _current?.track == track) return;
    await _crossfadeTo(track);
  }

  /// One-shot [sting] over the music, then back to the last loop.
  Future<void> playSting([Music sting = Music.legendarySting]) async {
    if (!_musicOn) return;
    final generation = await _crossfadeTo(sting);
    final playing = _current;
    if (playing == null) return;
    await playing.handle.completed;
    if (generation != _generation) return; // something else took over
    final back = _desired;
    if (back != null && _musicOn) {
      await _crossfadeTo(back);
    } else {
      _current = null;
    }
  }

  Future<void> stopMusic() async {
    _desired = null;
    await _fadeOutCurrent();
  }

  /// New settings from the Settings screen: applied at once.
  Future<void> applySettings(PlayerSettings next) async {
    final wasOn = _musicOn;
    _settings = next;
    if (wasOn && !_musicOn) {
      await _fadeOutCurrent();
    } else if (!wasOn && _musicOn && _desired != null) {
      await _crossfadeTo(_desired!);
    } else if (_current != null) {
      await _current!.handle.setVolume(_settings.musicVolume);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        _inBackground = true;
        unawaited(_current?.handle.pause());
      case AppLifecycleState.resumed:
        _inBackground = false;
        if (_settings.musicEnabled) unawaited(_current?.handle.resume());
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  bool get _musicOn =>
      _settings.musicEnabled && _settings.musicVolume > 0 && !_inBackground;

  Future<int> _crossfadeTo(Music track) async {
    final generation = ++_generation;
    final old = _current;
    final handle = await _backend.startMusic(track, 0);
    _current = _Playing(track, handle);
    await Future.wait([
      _ramp(handle, 0, _settings.musicVolume, generation),
      if (old != null) _fadeAndStop(old.handle),
    ]);
    return generation;
  }

  Future<void> _fadeOutCurrent() async {
    final old = _current;
    _current = null;
    _generation++;
    if (old != null) await _fadeAndStop(old.handle);
  }

  Future<void> _fadeAndStop(MusicHandle handle) async {
    await _ramp(handle, _settings.musicVolume, 0, null);
    await handle.stop();
  }

  /// Steps the volume from [from] to [to] over [crossfade]. A ramp that
  /// belongs to an older crossfade ([generation] changed) stops early.
  Future<void> _ramp(
    MusicHandle handle,
    double from,
    double to,
    int? generation,
  ) {
    final done = Completer<void>();
    var step = 0;
    Timer.periodic(crossfade ~/ _fadeSteps, (timer) {
      step++;
      final stale = generation != null && generation != _generation;
      if (stale || step >= _fadeSteps) {
        timer.cancel();
        if (!stale) unawaited(handle.setVolume(to));
        done.complete();
        return;
      }
      unawaited(handle.setVolume(from + (to - from) * step / _fadeSteps));
    });
    return done.future;
  }
}

class _Playing {
  const _Playing(this.track, this.handle);

  final Music track;
  final MusicHandle handle;
}
