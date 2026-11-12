import 'dart:async';

import 'package:flutter/foundation.dart';

import 'image_precacher.dart';

/// App-wide image downloads (SPEC §3 Images, §2.9 AC5). Lives in DI, so a
/// download keeps running when the Settings page closes.
///
/// - [downloadAll]: user-started, every character image, progress in
///   [progress], cancellable with [stop], resumable (cached files skip).
/// - [warmUp]: silent, automatic, small sets (owned cards, deck).
class ImageDownloadController {
  ImageDownloadController({ImageFetch fetch = diskCacheFetch})
    : _all = ImagePrecacher(fetch: fetch),
      _warm = ImagePrecacher(fetch: fetch, concurrency: 2);

  final ImagePrecacher _all;
  final ImagePrecacher _warm;
  final ValueNotifier<PrecacheProgress?> _progress = ValueNotifier(null);
  StreamSubscription<PrecacheProgress>? _sub;
  bool _stopped = false;

  /// Null until the first full download starts.
  ValueListenable<PrecacheProgress?> get progress => _progress;

  bool get running => _all.running;

  /// True after [stop] until the next start.
  bool get stopped => _stopped;

  void downloadAll(Iterable<String> urls) {
    if (_all.running) return;
    _stopped = false;
    unawaited(_sub?.cancel());
    _sub = _all.run(urls).listen((p) => _progress.value = p);
  }

  void stop() {
    _stopped = true;
    _all.cancel();
  }

  /// Fire and forget; never blocks a screen.
  Future<void> warmUp(Iterable<String> urls) async {
    if (_warm.running) return;
    await _warm.run(urls).drain<void>();
  }

  void dispose() {
    _all.cancel();
    _warm.cancel();
    unawaited(_sub?.cancel());
    _progress.dispose();
  }
}
