import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'theme/app_theme.dart';

/// Kök widget: yalnızca Türkçe (SPEC varsayım 3), yalnızca koyu tema.
class PortalCardsApp extends StatelessWidget {
  const PortalCardsApp({required this.router, super.key});

  final GoRouter router;

  static const Locale locale = Locale('tr');

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
