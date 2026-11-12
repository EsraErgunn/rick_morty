import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/images/image_precacher.dart';

void main() {
  test('at most 4 downloads at a time; all urls handled once', () async {
    var active = 0;
    var peak = 0;
    final seen = <String>[];
    final p = ImagePrecacher(
      fetch: (url) async {
        active++;
        peak = active > peak ? active : peak;
        seen.add(url);
        await Future<void>.delayed(const Duration(milliseconds: 2));
        active--;
        return true;
      },
    );
    final urls = [for (var i = 0; i < 30; i++) 'u$i', 'u1', 'u2'];

    final events = await p.run(urls).toList();

    expect(peak, 4);
    expect(seen.toSet(), hasLength(30));
    expect(seen, hasLength(30));
    expect(events.last.finished, isTrue);
    expect(events.last.complete, isTrue);
    expect(events.last.percent, 100);
  });

  test('failures are counted, skipped and never stop the run', () async {
    final p = ImagePrecacher(
      fetch: (url) async {
        if (url.endsWith('3')) throw StateError('404');
        return true;
      },
    );
    final last = await p.run([for (var i = 0; i < 10; i++) 'u$i']).last;
    expect(last.done, 10);
    expect(last.failed, 1);
    expect(last.complete, isFalse);
  });

  test(
    'cancel stops new downloads; a new run resumes (cached skipped)',
    () async {
      final cached = <String>{};
      final downloaded = <String>[];
      late ImagePrecacher p;
      p = ImagePrecacher(
        concurrency: 1,
        fetch: (url) async {
          if (cached.contains(url)) return false;
          downloaded.add(url);
          cached.add(url);
          if (downloaded.length == 3) p.cancel();
          return true;
        },
      );
      final urls = [for (var i = 0; i < 8; i++) 'u$i'];

      final first = await p.run(urls).last;
      expect(first.finished, isTrue);
      expect(first.done, 3);
      expect(downloaded, ['u0', 'u1', 'u2']);

      final second = await p.run(urls).last;
      expect(second.complete, isTrue);
      expect(downloaded, urls); // each url downloaded exactly once
    },
  );

  test('empty list finishes at 100 %', () async {
    final last = await ImagePrecacher(fetch: (_) async => true).run([]).last;
    expect(last.complete, isTrue);
    expect(last.percent, 100);
  });
}
