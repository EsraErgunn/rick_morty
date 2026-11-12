import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/sync_repository.dart';

/// Progress while syncing: status line, bar, percentage and item counter.
class SyncProgressView extends StatelessWidget {
  const SyncProgressView({required this.progress, super.key});

  final SyncProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.syncInProgress, style: AppTypography.body),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.ink, width: AppOutline.thin),
            borderRadius: AppRadius.pillAll,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress.fraction),
              duration: AppMotion.normal,
              curve: AppMotion.move,
              builder: (context, value, _) => LinearProgressIndicator(
                key: const ValueKey('sync-progress-bar'),
                value: value,
                minHeight: AppSizes.progressBar,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.syncPercent(progress.percent), style: AppTypography.stat),
            Text(
              l10n.syncCount(progress.downloaded, progress.total),
              style: AppTypography.stat.copyWith(color: AppColors.paperMuted),
            ),
          ],
        ),
      ],
    );
  }
}

/// Failure: what happened + "Tekrar dene" (SPEC §2.1 AC3).
class SyncErrorView extends StatelessWidget {
  const SyncErrorView({
    required this.connectionProblem,
    required this.onRetry,
    super.key,
  });

  final bool connectionProblem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          connectionProblem ? l10n.syncConnectionError : l10n.syncStorageError,
          textAlign: TextAlign.center,
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}
