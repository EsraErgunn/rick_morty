import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'theme/app_theme.dart';

/// Root widget: Turkish only (SPEC assumption 3), dark theme only.
class PortalCardsApp extends StatelessWidget {
  const PortalCardsApp({super.key});

  static const Locale locale = Locale('tr');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Text(
              AppLocalizations.of(context).appTitle,
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
        ),
      ),
    );
  }
}
