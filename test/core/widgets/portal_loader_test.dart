import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/theme/motion.dart';
import 'package:portalcards/core/widgets/portal/portal_view.dart';
import 'package:portalcards/core/widgets/portal_loader.dart';
import 'package:portalcards/core/widgets/shader_cache.dart';

/// `active` işaretini testin değiştirebildiği bir [PortalLoader] barındırır.
class _Host extends StatefulWidget {
  const _Host({required this.onSettled, this.reduceMotion = false});

  final VoidCallback onSettled;
  final bool reduceMotion;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool active = true;
  double intensity = 1;

  void setActive(bool value) => setState(() => active = value);

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQueryData(disableAnimations: widget.reduceMotion),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: PortalLoader(
        active: active,
        intensity: intensity,
        onSettled: widget.onSettled,
      ),
    ),
  );
}

Finder get _painted => find.descendant(
  of: find.byKey(const ValueKey('portal-loader')),
  matching: find.byType(CustomPaint),
);

void main() {
  late int settled;

  setUp(() => settled = 0);

  Future<_HostState> pumpHost(
    WidgetTester tester, {
    bool reduce = false,
  }) async {
    await tester.pumpWidget(
      _Host(onSettled: () => settled++, reduceMotion: reduce),
    );
    return tester.state<_HostState>(find.byType(_Host));
  }

  testWidgets('loads shorter than 300 ms never show the portal', (
    tester,
  ) async {
    final host = await pumpHost(tester);
    await tester.pump(const Duration(milliseconds: 250));
    expect(_painted, findsNothing);

    host.setActive(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(_painted, findsNothing);
    expect(settled, 1);
  });

  testWidgets('appears after 300 ms, scaling in from a point', (tester) async {
    await pumpHost(tester);
    await tester.pump(AppMotion.loaderShowDelay);
    await tester.pump();

    expect(_painted, findsOneWidget);
    final scale = tester.widget<ScaleTransition>(
      find.descendant(
        of: find.byKey(const ValueKey('portal-loader')),
        matching: find.byType(ScaleTransition),
      ),
    );
    expect(scale.scale.value, lessThan(0.1));

    await tester.pump(AppMotion.slow);
    expect(scale.scale.value, closeTo(1, 0.001));
  });

  testWidgets('once shown it stays at least 600 ms', (tester) async {
    final host = await pumpHost(tester);
    await tester.pump(AppMotion.loaderShowDelay);
    await tester.pump(const Duration(milliseconds: 100));

    host.setActive(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_painted, findsOneWidget);
    expect(settled, 0);

    // 100 + 400 + 100 = 600 ms görünür, sonra 300 ms kapanma.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(AppMotion.normal);
    await tester.pump(AppMotion.fast);

    expect(_painted, findsNothing);
    expect(settled, 1);
  });

  testWidgets('keeps spinning while active (no settle)', (tester) async {
    await pumpHost(tester);
    await tester.pump(AppMotion.loaderShowDelay);
    await tester.pump(const Duration(seconds: 5));
    expect(_painted, findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);
    expect(settled, 0);
  });

  testWidgets('reduced motion: fade only, no scale, no spin', (tester) async {
    await pumpHost(tester, reduce: true);
    await tester.pump(AppMotion.loaderShowDelay);
    await tester.pump();

    final loader = find.byKey(const ValueKey('portal-loader'));
    expect(
      find.descendant(of: loader, matching: find.byType(ScaleTransition)),
      findsNothing,
    );
    expect(
      find.descendant(of: loader, matching: find.byType(FadeTransition)),
      findsOneWidget,
    );
    // Yerleşir (sonsuz dönme yok); aksi hâlde pumpAndSettle zaman aşımına uğrardı.
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('disposes its controllers and timers', (tester) async {
    await pumpHost(tester);
    await tester.pump(AppMotion.loaderShowDelay);
    await tester.pumpWidget(const SizedBox());
    // Sızan bir ticker ya da bekleyen bir zamanlayıcı burada test çerçevesini başarısız kılar.
  });

  testWidgets('with a shader cache the inside is the PortalView (D8)', (
    tester,
  ) async {
    final cache = ShaderCache(loader: (_) => Future.error(StateError('x')));
    await cache.load();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PortalLoader(active: true, shaders: cache),
      ),
    );
    await tester.pump(AppMotion.loaderShowDelay);
    await tester.pump();
    expect(find.byType(PortalView), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
