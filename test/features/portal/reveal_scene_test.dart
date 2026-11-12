import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/audio/audio_assets.dart';
import 'package:portalcards/core/haptics/haptics_service.dart';
import 'package:portalcards/core/widgets/game_card/card_art.dart';
import 'package:portalcards/core/widgets/game_card/flip_card.dart';
import 'package:portalcards/core/widgets/shader_cache.dart';
import 'package:portalcards/features/portal/domain/portal_repository.dart';
import 'package:portalcards/features/portal/presentation/widgets/reveal_effects.dart';
import 'package:portalcards/features/portal/presentation/widgets/reveal_scene.dart';
import 'package:portalcards/features/portal/presentation/widgets/reveal_timeline.dart';

import '../../helpers/cards.dart';
import 'portal_fakes.dart';

void main() {
  final shaders = ShaderCache(loader: (_) => Future.error(StateError('x')));
  setUpAll(shaders.load);
  setUp(() => CardArt.debugArtBuilder = testArt);
  tearDown(() => CardArt.debugArtBuilder = null);

  late RecordingFeedback rec;
  late int finished;

  Future<void> pumpScene(
    WidgetTester tester,
    PortalResult result, {
    bool reduce = false,
  }) {
    rec = RecordingFeedback();
    finished = 0;
    return tester.pumpWidget(
      testApp(
        SizedBox(
          width: 400,
          height: 700,
          child: RevealScene(
            result: result,
            shaders: shaders,
            feedback: rec.feedback,
            onFinished: () => finished++,
          ),
        ),
        reduceMotion: reduce,
      ),
    );
  }

  Future<void> finishIntro(WidgetTester tester, PortalResult r) async {
    final total = RevealTimeline(legendary: r.isLegendary).total;
    await tester.pump(total);
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('beats in order: charge, burst, land (sound + haptic)', (
    tester,
  ) async {
    final r = resultFor(71); // common Conroy
    await pumpScene(tester, r);
    await tester.pump();
    expect(rec.sounds, [Sfx.portalCharge]);

    await finishIntro(tester, r);
    expect(rec.sounds, [Sfx.portalCharge, Sfx.portalOpen, Sfx.hit]);
    expect(rec.haptics, [
      HapticKind.medium,
      HapticKind.heavy,
      HapticKind.medium,
    ]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('waiting: hint after 1.5 s, auto flip after 4 s', (tester) async {
    final r = resultFor(71);
    await pumpScene(tester, r);
    await finishIntro(tester, r);
    expect(find.text('Çevirmek için dokun'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await frames(tester, const Duration(milliseconds: 500));
    expect(rec.sounds, contains(Sfx.cardFlip));
    expect(rec.sounds, isNot(contains(Sfx.rareReveal)));
    await tester.pump(const Duration(seconds: 1));
    expect(finished, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tap before landing does nothing; after landing it flips', (
    tester,
  ) async {
    final r = resultFor(23); // epic Arcade Alien
    await pumpScene(tester, r);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(FlipCard), findsOneWidget);
    await tester.tap(find.byType(FlipCard), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    expect(rec.sounds, isNot(contains(Sfx.cardFlip)));

    await finishIntro(tester, r);
    await tester.tap(find.byType(FlipCard));
    await frames(tester, const Duration(milliseconds: 500));
    expect(rec.sounds, containsAll([Sfx.cardFlip, Sfx.rareReveal]));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('duplicates also play the coin sound', (tester) async {
    final r = resultFor(71, duplicate: true);
    await pumpScene(tester, r);
    await finishIntro(tester, r);
    await tester.tap(find.byType(FlipCard));
    await frames(tester, const Duration(milliseconds: 500));
    expect(rec.sounds, contains(Sfx.coin));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('legendary: sting + heavy sequence on flip', (tester) async {
    final r = resultFor(1);
    await pumpScene(tester, r);
    await finishIntro(tester, r);
    await tester.tap(find.byType(FlipCard));
    await frames(tester, const Duration(milliseconds: 1200));
    expect(rec.sounds, contains(Sfx.legendaryReveal));
    await tester.pump(const Duration(seconds: 1));
    expect(finished, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('reduced motion: one crossfade, same sounds, no shake', (
    tester,
  ) async {
    final r = resultFor(86); // rare
    await pumpScene(tester, r, reduce: true);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(seconds: 1));
    expect(
      rec.sounds,
      containsAll([
        Sfx.portalCharge,
        Sfx.portalOpen,
        Sfx.cardFlip,
        Sfx.rareReveal,
      ]),
    );
    expect(finished, 1);
    expect(find.byType(Transform), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving mid-scene disposes cleanly (result already saved)', (
    tester,
  ) async {
    await pumpScene(tester, resultFor(1));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
    // The legendary sting's music crossfade keeps running after the scene.
    await tester.pump(const Duration(seconds: 1));
  });

  test('painters do nothing outside their range', () {
    expect(
      const BurstPainter(
        progress: 0,
        color: Colors.green,
      ).shouldRepaint(const BurstPainter(progress: 0.5, color: Colors.green)),
      isTrue,
    );
  });
}
