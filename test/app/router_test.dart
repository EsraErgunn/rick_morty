import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:portalcards/app/app.dart';
import 'package:portalcards/app/di.dart';
import 'package:portalcards/app/router.dart';

Future<GoRouter> _pumpApp(WidgetTester tester) async {
  final router = createRouter();
  await tester.pumpWidget(PortalCardsApp(router: router));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  /// Every route in SPEC §2 → its placeholder title.
  final routes = <String, String>{
    AppRoutes.splash: 'Yükleniyor',
    AppRoutes.menu: 'Ana menü',
    AppRoutes.portal: 'Portal',
    AppRoutes.collection: 'Koleksiyon',
    AppRoutes.cardDetail(1): 'Kart 1',
    AppRoutes.deck: 'Deste',
    AppRoutes.battle: 'Savaş',
    AppRoutes.album: 'Albüm',
    AppRoutes.albumPage(28): 'Bölüm 28',
    AppRoutes.settings: 'Ayarlar',
  };

  test('route paths match SPEC 2', () {
    expect(routes.keys, [
      '/splash',
      '/',
      '/portal',
      '/collection',
      '/collection/1',
      '/deck',
      '/battle',
      '/album',
      '/album/28',
      '/settings',
    ]);
  });

  for (final MapEntry(key: path, value: title) in routes.entries) {
    testWidgets('$path shows "$title"', (tester) async {
      final router = await _pumpApp(tester);
      router.go(path);
      await tester.pumpAndSettle();

      expect(router.state.uri.path, path);
      expect(find.text(title), findsOneWidget);
    });
  }

  testWidgets('starts on /splash', (tester) async {
    final router = await _pumpApp(tester);
    expect(router.state.uri.path, AppRoutes.splash);
  });

  testWidgets('unknown route shows "Sayfa bulunamadı" and returns to menu', (
    tester,
  ) async {
    final router = await _pumpApp(tester);
    router.go('/no/such/page');
    await tester.pumpAndSettle();

    expect(find.text('Sayfa bulunamadı'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Ana menü'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.menu);
    expect(find.text('Ana menü'), findsOneWidget);
  });

  group('DI', () {
    tearDown(() => getIt.reset());

    test('registers the router', () async {
      await configureDependencies();
      expect(getIt.isRegistered<GoRouter>(), isTrue);
      expect(
        getIt<GoRouter>().routeInformationProvider.value.uri.path,
        AppRoutes.splash,
      );
    });

    test('can be reset and configured again', () async {
      await configureDependencies();
      final first = getIt<GoRouter>();
      await getIt.reset();
      await configureDependencies();

      expect(getIt<GoRouter>(), isNot(same(first)));
    });
  });
}
