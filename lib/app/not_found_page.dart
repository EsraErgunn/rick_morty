import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme/spacing.dart';

/// Shown by the router for any unknown location.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.notFoundTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.menu),
                  child: Text(l10n.menuTitle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
