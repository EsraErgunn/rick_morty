import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';

import '../logging/app_logger.dart';

/// Puts one image into the disk cache. Returns false if it was already
/// cached (skipped), true if downloaded; throws on a failed download.
typedef ImageFetch = Future<bool> Function(String url);

/// Disk cache only, no decoding (SPEC §3 Images): the same cache that
/// `CachedNetworkImage` reads from.
Future<bool> diskCacheFetch(String url) async {
  final cache = CachedNetworkImageProvider.defaultCacheManager;
  if (await cache.getFileFromCache(url) != null) return false;
  await cache.downloadFile(url);
  return true;
}

/// Progress of one precache run.
final class PrecacheProgress {
  const PrecacheProgress({
    required this.done,
    required this.total,
    required this.failed,
    required this.finished,
  });

  /// URLs handled so far (downloaded, already cached or failed).
  final int done;
  final int total;
  final int failed;

  /// True on the last event (all handled, or cancelled).
  final bool finished;

  int get percent => total == 0 ? 100 : (done * 100 / total).floor();

  bool get complete => finished && done == total && failed == 0;
}

/// Warms the image disk cache with at most [concurrency] downloads at a
/// time (SPEC §3, §2.9 AC5). Cancel stops new downloads at once; running
/// it again resumes, because cached files are skipped.
class ImagePrecacher {
  ImagePrecacher({this._fetch = diskCacheFetch, this.concurrency = 4});

  final ImageFetch _fetch;
  final int concurrency;
  bool _cancelled = false;
  bool _running = false;

  bool get running => _running;

  void cancel() => _cancelled = true;

  /// Runs over [urls] (duplicates removed) and reports progress after each.
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
