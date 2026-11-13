import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';

import '../logging/app_logger.dart';

/// Tek bir görseli disk önbelleğine koyar. Zaten önbellekteyse false
/// (atlandı), indirildiyse true döner; indirme başarısız olursa hata fırlatır.
typedef ImageFetch = Future<bool> Function(String url);

/// Yalnızca disk önbelleği, çözümleme yok (SPEC §3 Görseller): `CachedNetworkImage`'ın
/// okuduğu önbelleğin aynısı.
Future<bool> diskCacheFetch(String url) async {
  final cache = CachedNetworkImageProvider.defaultCacheManager;
  if (await cache.getFileFromCache(url) != null) return false;
  await cache.downloadFile(url);
  return true;
}

/// Tek bir önbelleğe alma çalışmasının ilerlemesi.
final class PrecacheProgress {
  const PrecacheProgress({
    required this.done,
    required this.total,
    required this.failed,
    required this.finished,
  });

  /// Şimdiye kadar işlenen URL'ler (indirilen, zaten önbellekte olan veya başarısız).
  final int done;
  final int total;
  final int failed;

  /// Son olayda true (hepsi işlendi ya da iptal edildi).
  final bool finished;

  int get percent => total == 0 ? 100 : (done * 100 / total).floor();

  bool get complete => finished && done == total && failed == 0;
}

/// Görsel disk önbelleğini aynı anda en fazla [concurrency] indirmeyle
/// ısıtır (SPEC §3, §2.9 AC5). İptal yeni indirmeleri hemen durdurur; tekrar
/// çalıştırınca kaldığı yerden devam eder, çünkü önbellekteki dosyalar atlanır.
class ImagePrecacher {
  ImagePrecacher({this._fetch = diskCacheFetch, this.concurrency = 4});

  final ImageFetch _fetch;
  final int concurrency;
  bool _cancelled = false;
  bool _running = false;

  bool get running => _running;

  void cancel() => _cancelled = true;

  /// [urls] üzerinden geçer (tekrarlar çıkarılır) ve her birinden sonra ilerlemeyi bildirir.
  Stream<PrecacheProgress> run(Iterable<String> urls) {
    final list = urls.toSet().toList();
    final out = StreamController<PrecacheProgress>();
    var next = 0;
    var done = 0;
    var failed = 0;
    _cancelled = false;
    _running = true;

    PrecacheProgress progress({bool finished = false}) => PrecacheProgress(
      done: done,
      total: list.length,
      failed: failed,
      finished: finished,
    );

    Future<void> worker() async {
      while (!_cancelled && next < list.length) {
        final url = list[next++];
        try {
          await _fetch(url);
        } on Object catch (e) {
          failed++;
          AppLogger.warning('image precache failed', e);
        }
        done++;
        if (!out.isClosed) out.add(progress());
      }
    }

    Future<void>(() async {
      await Future.wait([for (var i = 0; i < concurrency; i++) worker()]);
      _running = false;
      out.add(progress(finished: true));
      await out.close();
    });
    return out.stream;
  }
}
