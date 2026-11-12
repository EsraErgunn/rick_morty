import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/app.dart';
import 'package:portalcards/app/router.dart';
import 'package:portalcards/app/theme/colors.dart';

import '../features/sync/fake_sync_repository.dart';

void main() {
  testWidgets('app starts on splash in Turkish, dark, and opens the menu', (
    tester,
  ) async {
    final router = createRouter(syncRepository: FakeSyncRepository());
    await tester.pumpWidget(PortalCardsApp(router: router));

    expect(router.state.uri.path, AppRoutes.splash);
    expect(find.text('Portal Cards'), findsOneWidget);

    final context = tester.element(find.byType(Scaffold));
    expect(Localizations.localeOf(context), const Locale('tr'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.voidBase);

    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.menu);
    expect(find.text('Ana menü'), findsOneWidget);
  });
}
