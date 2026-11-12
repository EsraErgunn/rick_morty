import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/theme/card_style.dart';
import 'package:portalcards/core/game/rarity.dart';
import 'package:portalcards/core/widgets/game_card/card_art.dart';
import 'package:portalcards/core/widgets/game_card/game_card.dart';
import 'package:portalcards/core/widgets/game_card/holo_layer.dart';
import 'package:portalcards/core/widgets/game_card/shader_cache.dart';

import '../../helpers/cards.dart';

void main() {
  group('ShaderCache', () {
    test('loads holo.frag once, however often load() is called', () async {
      var calls = 0;
      final cache = ShaderCache(
        loader: (asset) async {
          calls++;
          expect(asset, 'shaders/holo.frag');
          throw UnsupportedError('no GPU in unit tests');
        },
      );

      await Future.wait([cache.load(), cache.load()]);
      await cache.load();

      expect(calls, 1);
    });

    test(
      'a failed load leaves holo null and marks failed (fallback)',
      () async {
        final cache = ShaderCache(loader: (_) => Future.error(StateError('x')));
        await cache.load();
        expect(cache.holo, isNull);
        expect(cache.failed, isTrue);
      },
    );

    test('pubspec lists the shader under flutter: shaders:', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(
        RegExp(r'shaders:\s*\n\s*- shaders/holo\.frag').hasMatch(pubspec),
        isTrue,
      );
    });
  });

  group('HoloLayer', () {
    final tilt = ValueNotifier(Offset.zero);
    final failed = ShaderCache(loader: (_) => Future.error(StateError('x')));

    setUpAll(failed.load);
    setUp(() => CardArt.debugArtBuilder = testArt);
    tearDown(() => CardArt.debugArtBuilder = null);

    Future<void> pumpHolo(WidgetTester tester, int id, ShaderCache cache) {
      final data = fixtureCard(id);
      return tester.pumpWidget(
        testApp(
          SizedBox(
            width: CardMetrics.designWidth,
            child: GameCard(
              data: data,
              holo: HoloLayer(rarity: data.rarity, tilt: tilt, shaders: cache),
            ),
          ),
        ),
      );
    }

    testWidgets('common cards get no holo layer', (tester) async {
      await pumpHolo(tester, 71, failed);
      expect(find.byKey(const ValueKey('holo-fallback')), findsNothing);
      expect(find.byKey(const ValueKey('holo-shader')), findsNothing);
    });

    testWidgets('without the shader rare+ cards draw the fallback sheen', (
      tester,
    ) async {
      for (final id in [86, 23, 1]) {
        await pumpHolo(tester, id, failed);
        expect(find.byKey(const ValueKey('holo-fallback')), findsOneWidget);
      }
    });

    testWidgets('with the compiled shader legendary uses holo.frag', (
      tester,
    ) async {
      final cache = ShaderCache();
      await tester.runAsync(cache.load);
      if (cache.holo == null) {
        markTestSkipped('shader compiler not available in this test run');
        return;
      }
      await pumpHolo(tester, 1, cache);
      expect(find.byKey(const ValueKey('holo-shader')), findsOneWidget);

      tilt.value = const Offset(0.5, -0.3);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('holo strength per rarity is 0 / 0.35 / 0.65 / 1.0', () {
      expect(Rarity.values.map((r) => r.holoStrength), [0, 0.35, 0.65, 1]);
    });
  });
}
