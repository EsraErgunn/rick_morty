import 'package:flutter/material.dart';

import 'theme/spacing.dart';

/// Özelliği henüz yazılmamış rotalar için geçici ekran.
/// Ekran başlığını (ve isteğe bağlı bir [action], ör. debug bağlantısı) gösterir.
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
