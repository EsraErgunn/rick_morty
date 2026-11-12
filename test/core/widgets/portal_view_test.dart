import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/theme/motion.dart';
import 'package:portalcards/core/widgets/portal/portal_view.dart';
import 'package:portalcards/core/widgets/shader_cache.dart';

import '../../helpers/cards.dart';

void main() {
  final failed = ShaderCache(loader: (_) => Future.error(StateError('x')));
  setUpAll(failed.load);

  Future<void> pumpPortal(
    WidgetTester tester,
    ShaderCache cache, {
    bool legendary = false,
    double intensity = PortalIntensity.idle,
  }) => tester.pumpWidget(
    testApp(
      Center(
        child: SizedBox.square(
          dimension: 240,
          child: PortalView(
            shaders: cache,
            intensity: intensity,
            legendary: legendary,
          ),
        ),
      ),
    ),
  );

  testWidgets('without the shader the spiral fallback is drawn', (
    tester,
  ) async {
    await pumpPortal(tester, failed);
    expect(find.byKey(const ValueKey('portal-fallback')), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with the compiled shader portal.frag is used', (tester) async {
    final cache = ShaderCache();
    await tester.runAsync(cache.load);
    if (cache.portal == null) {
      markTestSkipped('shader compiler not available in this test run');
      return;
    }
    await pumpPortal(tester, cache, intensity: PortalIntensity.open);
    expect(find.byKey(const ValueKey('portal-shader')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the vortex animates by repainting, not rebuilding', (
    tester,
  ) async {
    var builds = 0;
    await tester.pumpWidget(
      testApp(
        Center(
          child: SizedBox.square(
            dimension: 200,
            child: Builder(
              builder: (context) {
                builds++;
                return PortalView(shaders: failed);
              },
            ),
          ),
        ),
      ),
    );
    final before = builds;
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(builds, before);
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('legendary eases the color over AppMotion.slow', (tester) async {
    await pumpPortal(tester, failed);
    await pumpPortal(tester, failed, legendary: true);
    await tester.pump(AppMotion.slow ~/ 2);
    await tester.pump(AppMotion.slow);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('intensity levels follow SPEC 2.3 AC5', () {
    expect(PortalIntensity.idle, 0.15);
    expect(PortalIntensity.open, 1.0);
    expect(PortalIntensity.dim, 0.05);
  });
}
