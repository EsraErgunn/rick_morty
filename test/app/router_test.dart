import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:portalcards/app/app.dart';
import 'package:portalcards/app/di.dart';
import 'package:portalcards/app/router.dart';

import '../core/storage/hive_test_helper.dart';
import '../features/sync/fake_sync_repository.dart';

Future<GoRouter> _pumpApp(WidgetTester tester) async {
  final router = createRouter(syncRepository: FakeSyncRepository(hold: true));
  await tester.pumpWidget(PortalCardsApp(router: router));
  // Splash keeps syncing (held), so its portal never settles: pump once.
  await tester.pump();
  return router;
}

void main() {
  /// Every placeholder route in SPEC §2 → its title (splash is real now).
  final routes = <String, String>{
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
    expect(
      [AppRoutes.splash, ...routes.keys],
      [
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
      ],
    );
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
    expect(find.text('Evrenler indiriliyor'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // dispose loader timers
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

  group('card lab (debug only)', () {
    testWidgets('debug builds register /debug/card-lab with a menu link', (
      tester,
    ) async {
      final router = await _pumpApp(tester);
      router.go(AppRoutes.menu);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Kart laboratuvarı'),
      );
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppRoutes.cardLab);
      expect(find.textContaining('Önce verileri indir'), findsOneWidget);
    });

    testWidgets('release builds have no card lab route and no link', (
      tester,
    ) async {
      final router = createRouter(
        syncRepository: FakeSyncRepository(hold: true),
        debugRoutes: false,
        initialLocation: AppRoutes.menu,
      );
      await tester.pumpWidget(PortalCardsApp(router: router));
      await tester.pumpAndSettle();
      expect(find.text('Kart laboratuvarı'), findsNothing);

      router.go(AppRoutes.cardLab);
      await tester.pumpAndSettle();
      expect(find.text('Sayfa bulunamadı'), findsOneWidget);
    });
  });

  group('DI', () {
    final hiveDir = useTempHive();

    tearDown(() => getIt.reset());

    test('registers the router, starting on /splash', () async {
      await configureDependencies(storageDirectory: hiveDir());
      expect(getIt.isRegistered<GoRouter>(), isTrue);
      expect(
        getIt<GoRouter>().routeInformationProvider.value.uri.path,
        AppRoutes.splash,
      );
    });

    test('can be reset and configured again', () async {
      await configureDependencies(storageDirectory: hiveDir());
      final first = getIt<GoRouter>();
      await getIt.reset();
      await configureDependencies(storageDirectory: hiveDir());

      expect(getIt<GoRouter>(), isNot(same(first)));
    });
  });
}
