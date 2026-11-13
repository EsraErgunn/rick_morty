import 'package:flutter/material.dart';

import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/shader_cache.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/portal_repository.dart';
import '../portal_feedback.dart';
import 'reveal_scene.dart';

/// Açılış sahnesi, sonra (açılınca) kazanılan ve sonraki eylemler.
class PortalResultView extends StatelessWidget {
  const PortalResultView({
    required this.result,
    required this.shaders,
    required this.feedback,
    required this.revealed,
    required this.onFinished,
    required this.onOpenAgain,
    required this.onGoToCollection,
    super.key,
  });

  final PortalResult result;
  final ShaderCache shaders;
  final PortalFeedback feedback;
  final bool revealed;
  final VoidCallback onFinished;
  final VoidCallback onOpenAgain;
  final VoidCallback onGoToCollection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: RevealScene(
            result: result,
            shaders: shaders,
            feedback: feedback,
            onFinished: onFinished,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: AppMotion.normal,
          child: !revealed
              ? const SizedBox(height: AppSpacing.xxl)
              : Column(
                  key: const ValueKey('reveal-actions'),
                  children: [
                    Text(
                      result.isDuplicate
                          ? l10n.portalDuplicate(result.duplicateCoins)
                          : l10n.portalNewCard,
                      style: AppTypography.title,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onGoToCollection,
                            child: Text(l10n.portalToCollection),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              feedback.button();
                              onOpenAgain();
                            },
                            child: Text(l10n.portalOpenAgain),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
