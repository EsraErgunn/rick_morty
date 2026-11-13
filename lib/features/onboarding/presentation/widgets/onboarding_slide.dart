import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';

/// Tek bir tanıtım sayfası: çizim, kısa başlık, tek cümle.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.art,
    required this.title,
    required this.body,
    super.key,
  });

  final Widget art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
    child: Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.onboardingArt,
                maxHeight: AppSizes.onboardingArt,
              ),
              child: AspectRatio(aspectRatio: 1, child: art),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, textAlign: TextAlign.center, style: AppTypography.headline),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    ),
  );
}

/// Sayfa noktaları; mevcut olan daha geniş bir haptır.
class PageDots extends StatelessWidget {
  const PageDots({
    required this.count,
    required this.current,
    required this.label,
    super.key,
  });

  final int count;
  final int current;

  /// Ekran okuyucu metni ("Sayfa 2 / 4").
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.move,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              width: i == current
                  ? AppSizes.onboardingDotActive
                  : AppSizes.onboardingDot,
              height: AppSizes.onboardingDot,
              decoration: BoxDecoration(
                color: i == current ? AppColors.portal : AppColors.paperMuted,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
        ],
      ),
    ),
  );
}
