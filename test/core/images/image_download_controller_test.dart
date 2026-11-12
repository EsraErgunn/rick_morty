import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/audio/audio_service.dart';
import 'package:portalcards/core/feedback/ui_feedback.dart';
import 'package:portalcards/core/haptics/haptics_service.dart';
import 'package:portalcards/core/images/image_download_controller.dart';
import 'package:portalcards/features/settings/presentation/widgets/image_download_tile.dart';

import '../../helpers/cards.dart';
import '../../helpers/fake_audio.dart';

void main() {
  final urls = [for (var i = 0; i < 12; i++) 'https://x/$i.jpeg'];

  test('downloadAll reports progress to the end', () async {
    final c = ImageDownloadController(fetch: (_) async => true);
    c.downloadAll(urls);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.progress.value!.complete, isTrue);
    expect(c.progress.value!.total, 12);
    c.dispose();
  });

  test('stop, then start again resumes without re-downloading', () async {
    final cached = <String>{};
    late ImageDownloadController c;
    var downloads = 0;
    c = ImageDownloadController(
      fetch: (url) async {
        if (!cached.add(url)) return false;
        downloads++;
        if (downloads == 5) c.stop();
        await Future<void>.delayed(Duration.zero);
        return true;
      },
    );
    c.downloadAll(urls);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.stopped, isTrue);
    expect(c.progress.value!.complete, isFalse);

    c.downloadAll(urls);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.progress.value!.complete, isTrue);
    expect(downloads, 12);
    c.dispose();
  });

  test(
    'warmUp downloads silently (no progress for the settings row)',
    () async {
      final got = <String>[];
      final c = ImageDownloadController(
        fetch: (u) async {
          got.add(u);
          return true;
        },
      );
      await c.warmUp(urls.take(3));
      expect(got, hasLength(3));
      expect(c.progress.value, isNull);
      c.dispose();
    },
  );

  testWidgets('settings row: start, then "İndirildi"', (tester) async {
    final c = ImageDownloadController(fetch: (_) async => true);
    addTearDown(c.dispose);
    final audio = AudioService(backend: FakeBackend());
    await tester.pumpWidget(
      testApp(
        ImageDownloadTile(
          controller: c,
          urls: () => urls,
          feedback: UiFeedback(
            audio: audio,
            haptics: HapticsService(driver: (_) async {}),
          ),
        ),
      ),
    );
    expect(find.text('Tüm görselleri çevrimdışı için indir'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('images-start')));
    await frames(tester, const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('images-done')), findsOneWidget);
  });
}
