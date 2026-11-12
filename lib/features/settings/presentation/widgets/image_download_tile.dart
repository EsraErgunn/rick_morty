import 'package:flutter/material.dart';

import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/feedback/ui_feedback.dart';
import '../../../../core/images/image_download_controller.dart';
import '../../../../core/images/image_precacher.dart';
import '../../../../l10n/app_localizations.dart';

/// "Tüm görselleri çevrimdışı için indir" (SPEC §2.9 AC5): start, progress
/// `%X · done/total`, Durdur, resume, "İndirildi".
class ImageDownloadTile extends StatelessWidget {
  const ImageDownloadTile({
    required this.controller,
    required this.urls,
    required this.feedback,
    super.key,
  });

  final ImageDownloadController controller;

  /// Every character image (read when the user starts).
  final List<String> Function() urls;
  final UiFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<PrecacheProgress?>(
      valueListenable: controller.progress,
      builder: (context, p, _) {
        final running = p != null && !p.finished;
        final Widget status = switch (p) {
          null => const SizedBox.shrink(),
          final p when !p.finished => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: p.total == 0 ? 1 : p.done / p.total),
                duration: AppMotion.normal,
                builder: (context, v, _) => LinearProgressIndicator(value: v),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.settingsImagesProgress(p.percent, p.done, p.total),
                style: AppTypography.stat,
              ),
            ],
          ),
          final p when p.complete => Text(
            l10n.settingsImagesDone,
            key: const ValueKey('images-done'),
            style: AppTypography.caption,
          ),
          final p when p.failed > 0 => Text(
            l10n.settingsImagesFailed(p.failed),
            style: AppTypography.caption,
          ),
          _ => Text(l10n.settingsImagesStopped, style: AppTypography.caption),
        };
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              running
                  ? OutlinedButton(
                      key: const ValueKey('images-stop'),
                      onPressed: () {
                        feedback.tap();
                        controller.stop();
                      },
                      child: Text(l10n.settingsImagesStop),
                    )
                  : OutlinedButton(
                      key: const ValueKey('images-start'),
                      onPressed: () {
                        feedback.tap();
                        controller.downloadAll(urls());
                      },
                      child: Text(l10n.settingsImages),
                    ),
              const SizedBox(height: AppSpacing.xs),
              status,
            ],
          ),
        );
      },
    );
  }
}
