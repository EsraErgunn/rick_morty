import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:portalcards/app/app.dart';
import 'package:portalcards/app/router.dart';
import 'package:portalcards/core/widgets/app_back_button.dart';

import '../features/sync/fake_sync_repository.dart';

void main() {
  late int taps;

  setUp(() => taps = 0);

  /// A stand-in page with the same back button the real pages use.
  Widget page(String name) => Scaffold(
    appBar: AppBar(
      leading: AppBackButton(onFeedback: () => taps++),
      title: Text(name),
    ),
  );

  Future<GoRouter> pumpAt(WidgetTester tester, String location) async {
    final router = createRouter(
      syncRepository: FakeSyncRepository(),
      initialLocation: AppRoutes.menu,
      menuPage: (_) => const Scaffold(body: Text('menu')),
      portalPage: (_) => page('portal'),
      collectionPage: (_) => page('collection'),
      cardDetailPage: (_, id) => page('card $id'),
      deckPage: (_) => page('deck'),
      battlePage: (_) => page('battle'),
      settingsPage: (_) => page('settings'),
    );
    await tester.pumpWidget(PortalCardsApp(router: router));
    router.go(location);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, location);
    return router;
  }

  /// Screen → the screen its back button (and Android back) returns to.
  final parents = <String, String>{
    AppRoutes.portal: AppRoutes.menu,
    AppRoutes.collection: AppRoutes.menu,
    AppRoutes.cardDetail(1): AppRoutes.collection,
    AppRoutes.deck: AppRoutes.menu,
    AppRoutes.battle: AppRoutes.menu,
    AppRoutes.settings: AppRoutes.menu,
  };

  for (final MapEntry(key: path, value: parent) in parents.entries) {
    testWidgets('$path: back button returns to $parent with a tap sound', (
      tester,
    ) async {
      final router = await pumpAt(tester, path);
      await tester.tap(find.byKey(AppBackButton.buttonKey));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, parent);
      expect(taps, 1);
    });

    testWidgets('$path: Android back returns to $parent', (tester) async {
      final router = await pumpAt(tester, path);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, parent);
    });
  }

  testWidgets('back button is at least 48 dp', (tester) async {
    await pumpAt(tester, AppRoutes.deck);
    final size = tester.getSize(find.byKey(AppBackButton.buttonKey));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('card detail → collection → menu, step by step', (tester) async {
    final router = await pumpAt(tester, AppRoutes.cardDetail(2));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.collection);
    await tester.tap(find.byKey(AppBackButton.buttonKey));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.menu);
  });
}
