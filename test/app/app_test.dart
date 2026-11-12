import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/app.dart';
import 'package:portalcards/app/theme/colors.dart';

void main() {
  testWidgets('app starts in Turkish with the dark void background', (
    tester,
  ) async {
    await tester.pumpWidget(const PortalCardsApp());
    await tester.pumpAndSettle();

    expect(find.text('Portal Cards'), findsOneWidget);

    final context = tester.element(find.byType(Scaffold));
    expect(Localizations.localeOf(context), const Locale('tr'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.voidBase);
  });
}
