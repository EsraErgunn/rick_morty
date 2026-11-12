import 'package:flutter/material.dart';

import 'theme/spacing.dart';

/// Temporary screen for routes whose feature is not built yet.
/// Shows the screen title only.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
        ),
      ),
    );
  }
}
