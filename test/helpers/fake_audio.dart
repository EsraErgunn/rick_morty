import 'dart:async';

import 'package:portalcards/core/audio/audio_assets.dart';
import 'package:portalcards/core/audio/audio_backend.dart';

class FakeHandle implements MusicHandle {
  FakeHandle(this.track, this.volume);

  final Music track;
  double volume;
  bool paused = false;
  bool stopped = false;
  final Completer<void> done = Completer<void>();

  @override
  Future<void> get completed => done.future;

  @override
  Future<void> setVolume(double v) async => volume = v;

  @override
  Future<void> pause() async => paused = true;

  @override
  Future<void> resume() async => paused = false;

  @override
  Future<void> stop() async {
    stopped = true;
    if (!done.isCompleted) done.complete();
  }
}

class FakeBackend implements AudioBackend {
  final List<(Sfx, double)> sfx = [];
  final List<FakeHandle> music = [];
  Set<Sfx> preloaded = {};

  List<FakeHandle> get live => music.where((h) => !h.stopped).toList();

  @override
  Future<void> preload(Iterable<Sfx> sounds) async =>
      preloaded = sounds.toSet();

  @override
  Future<void> playSfx(Sfx sound, double volume) async =>
      sfx.add((sound, volume));

  @override
  Future<MusicHandle> startMusic(Music track, double volume) async {
    final h = FakeHandle(track, volume);
    music.add(h);
    return h;
  }
}
