import 'package:flutter/material.dart';

import 'theme/spacing.dart';

/// Temporary screen for routes whose feature is not built yet.
/// Shows the screen title (and an optional [action], e.g. a debug link).
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({required this.title, this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                if (action case final action?) ...[
                  const SizedBox(height: AppSpacing.lg),
                  action,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
