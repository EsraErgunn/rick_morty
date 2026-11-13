import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/theme/app_theme.dart';
import 'package:portalcards/app/theme/colors.dart';
import 'package:portalcards/core/cards/card_factory.dart';
import 'package:portalcards/core/cards/game_card_data.dart';
import 'package:portalcards/features/sync/data/mappers.dart';
import 'package:portalcards/l10n/app_localizations.dart';

import '../fixtures/fixtures.dart';

/// Gerçek fabrika üzerinden bir fikstürden gerçek kart verisi.
GameCardData fixtureCard(int id) => CardFactory.fromCharacter(
  parseCharacter(loadCharacter(id)).getOrElse((f) => throw StateError('$f')),
);

/// Nadirlik başına bir fikstür: sıradan Conroy, nadir Cyclops Rick, epik Arcade
/// Alien, efsanevi Rick.
const List<int> oneCardPerRarity = [71, 86, 23, 1];

/// Düz görsel yedeği (testlerde ağ yok).
Widget testArt(String url, String name) =>
    const ColoredBox(color: AppColors.portalHot);

/// [child] etrafında tema ve Türkçe l10n bulunan Material uygulaması.
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

/// [total] süresini 50 ms'lik karelerle ilerletir, böylece zincirleme animasyonlar (biri
/// diğeri bitince başlayan) bir cihazdaki gibi kare alır.
Future<void> frames(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}
