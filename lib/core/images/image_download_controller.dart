import 'dart:async';

import 'package:flutter/foundation.dart';

import 'image_precacher.dart';

/// Uygulama genelinde görsel indirmeleri (SPEC §3 Görseller, §2.9 AC5). DI içinde yaşar,
/// böylece Ayarlar sayfası kapansa da indirme sürer.
///
/// - [downloadAll]: kullanıcı başlatır, tüm karakter görselleri, ilerleme
///   [progress] içinde, [stop] ile iptal edilir, kaldığı yerden devam eder (önbellekteki dosyalar atlanır).
/// - [warmUp]: sessiz, otomatik, küçük kümeler (sahip olunan kartlar, deste).
class ImageDownloadController {
  ImageDownloadController({ImageFetch fetch = diskCacheFetch})
    : _all = ImagePrecacher(fetch: fetch),
      _warm = ImagePrecacher(fetch: fetch, concurrency: 2);

  final ImagePrecacher _all;
  final ImagePrecacher _warm;
  final ValueNotifier<PrecacheProgress?> _progress = ValueNotifier(null);
  StreamSubscription<PrecacheProgress>? _sub;
  bool _stopped = false;

  /// İlk tam indirme başlayana kadar null.
  ValueListenable<PrecacheProgress?> get progress => _progress;

  bool get running => _all.running;

  /// [stop] sonrasında, bir sonraki başlatmaya kadar true.
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

  /// Başlat ve unut; hiçbir ekranı engellemez.
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
