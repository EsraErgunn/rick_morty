import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/album_repository.dart';

/// One episode row: code, name, `owned/total` and a progress bar.
class EpisodeTile extends StatelessWidget {
  const EpisodeTile({required this.episode, required this.onTap, super.key});

  final AlbumEpisode episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = episode;
    final ratio = e.total == 0 ? 0.0 : e.owned / e.total;
    return Material(
      color: AppColors.voidRaised,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: BorderSide(
          color: e.complete ? AppColors.portal : AppColors.ink,
          width: AppOutline.thin,
        ),
      ),
      child: InkWell(
        key: ValueKey('episode-${e.id}'),
        borderRadius: AppRadius.cardAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    e.code,
                    style: AppTypography.label.copyWith(
                      color: AppColors.portal,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      e.name,
                      style: AppTypography.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    e.complete
                        ? l10n.albumDone
                        : l10n.menuCount(e.owned, e.total),
                    style: AppTypography.caption.copyWith(
                      color: e.complete ? AppColors.portal : AppColors.paper,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: AppRadius.pillAll,
                child: SizedBox(
                  height: AppSizes.hpBar,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: AppColors.ink),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: ratio,
                        child: const ColoredBox(color: AppColors.portal),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
