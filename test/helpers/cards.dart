import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/theme/app_theme.dart';
import 'package:portalcards/app/theme/colors.dart';
import 'package:portalcards/core/cards/card_factory.dart';
import 'package:portalcards/core/cards/game_card_data.dart';
import 'package:portalcards/features/sync/data/mappers.dart';
import 'package:portalcards/l10n/app_localizations.dart';

import '../fixtures/fixtures.dart';

/// Real card data from a fixture through the real factory.
GameCardData fixtureCard(int id) => CardFactory.fromCharacter(
  parseCharacter(loadCharacter(id)).getOrElse((f) => throw StateError('$f')),
);

/// One fixture per rarity: common Conroy, rare Cyclops Rick, epic Arcade
/// Alien, legendary Rick.
const List<int> oneCardPerRarity = [71, 86, 23, 1];

/// Flat art stand-in (no network in tests).
Widget testArt(String url, String name) =>
    const ColoredBox(color: AppColors.portalHot);

/// Material app with theme and Turkish l10n around [child].
Widget testApp(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.dark,
  locale: const Locale('tr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: child),
  ),
);

/// Advances [total] in 50 ms frames, so chained animations (one starting
/// when another ends) all get frames, as on a device.
Future<void> frames(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}
