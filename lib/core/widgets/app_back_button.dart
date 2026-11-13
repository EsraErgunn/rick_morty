import 'package:flutter/material.dart';

import '../../app/theme/spacing.dart';
import '../../l10n/app_localizations.dart';

/// Menü dışındaki her ekranın görünür geri butonu: tema ikon
/// stili, en az 48 dp dokunma alanı, [onFeedback] (button_tap) çalar
/// ve sonra geri döner. [PopScope] olan bir sayfa (savaş) yine söz sahibidir,
/// çünkü varsayılan geri dönüş [Navigator.maybePop]'tur; [onPressed] bunun yerine geçer.
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
