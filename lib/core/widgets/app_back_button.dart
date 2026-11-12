import 'package:flutter/material.dart';

import '../../app/theme/spacing.dart';
import '../../l10n/app_localizations.dart';

/// The visible back button of every screen except the menu: theme icon
/// style, at least a 48 dp touch target, plays [onFeedback] (button_tap)
/// and then pops. A page with a [PopScope] (battle) still gets its say,
/// because the default pop is [Navigator.maybePop]; [onPressed] replaces it.
class AppBackButton extends StatelessWidget {
  const AppBackButton({required this.onFeedback, this.onPressed, super.key});

  final VoidCallback onFeedback;
  final VoidCallback? onPressed;

  static const Key buttonKey = ValueKey('app-back');

  @override
  Widget build(BuildContext context) => IconButton(
    key: buttonKey,
    tooltip: AppLocalizations.of(context).backTooltip,
    constraints: const BoxConstraints(
      minWidth: AppSizes.minTouch,
      minHeight: AppSizes.minTouch,
    ),
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () {
      onFeedback();
      if (onPressed case final custom?) {
        custom();
      } else {
        Navigator.of(context).maybePop();
      }
    },
  );
}
