import 'dart:async';

import 'package:flutter/widgets.dart';

import '../storage/player_state.dart';
import 'audio_assets.dart';
import 'audio_backend.dart';

/// Uygulamadaki tüm sesler buradan geçer (animasyon-ses kuralları).
///
/// - SFX: önceden yüklenmiş havuz, üst üste binebilir, `soundEnabled` ve
///   `sfxVolume` ayarlarına uyar.
/// - Müzik: aynı anda tek parça, parçalar arasında geçişli solma yapar,
///   `musicEnabled` ve `musicVolume` ayarlarına uyar, arka planda duraklar.
/// - [playSting] tek seferlik bir parça çalar, sonra en son istenen döngüye
///   döner (efsanevi açılış, SPEC §4.3).
class AudioService with WidgetsBindingObserver {
  AudioService({
    required this._backend,
    this._settings = const PlayerSettings(),
  });

  /// Müzik geçişli solma süresi (görsel bir token değil: ses zamanlaması).
  static const Duration crossfade = Duration(milliseconds: 800);
  static const int _fadeSteps = 16;

  final AudioBackend _backend;
  PlayerSettings _settings;

  _Playing? _current;
  Music? _desired;
  int _generation = 0;
  bool _inBackground = false;

  PlayerSettings get settings => _settings;

  /// Şu an çalan parça (sessizse null).
  Music? get currentMusic => _current?.track;

  /// Tüm ses efektlerini yükler (açılışta bir kez çağır).
  Future<void> preload() => _backend.preload(Sfx.values);

  /// Uygulama yaşam döngüsü olaylarına kaydolur (arka planda duraklatma).
  void attachLifecycle() => WidgetsBinding.instance.addObserver(this);

  void detachLifecycle() => WidgetsBinding.instance.removeObserver(this);

  Future<void> play(Sfx sound) async {
    if (!_settings.soundEnabled || _settings.sfxVolume <= 0) return;
    await _backend.playSfx(sound, _settings.sfxVolume);
  }

  /// [track] parçasını arka plan döngüsü olarak çalar (mevcut parçadan geçişli solmayla).
  Future<void> playMusic(Music track) async {
    _desired = track;
    if (!_musicOn || _current?.track == track) return;
    await _crossfadeTo(track);
  }

  /// Müziğin üstünde tek seferlik [sting], sonra son döngüye geri döner.
  Future<void> playSting([Music sting = Music.legendarySting]) async {
    if (!_musicOn) return;
    final generation = await _crossfadeTo(sting);
    final playing = _current;
    if (playing == null) return;
    await playing.handle.completed;
    if (generation != _generation) return; // araya başka bir şey girdi
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

  /// Ayarlar ekranından gelen yeni ayarlar: hemen uygulanır.
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

  /// Sesi [crossfade] süresince [from] değerinden [to] değerine kademeli değiştirir.
  /// Daha eski bir geçişe ait kademe ([generation] değiştiyse) erken durur.
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
