import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';

/// HP bar (SPEC §4.7): tweens over `normal`; yellow at ≤ 50 %, red at ≤ 20 %.
class HpBar extends StatelessWidget {
  const HpBar({required this.hp, required this.maxHp, super.key});

  final int hp;
  final int maxHp;

  static const double warnAt = 0.5;
  static const double dangerAt = 0.2;

  static Color colorFor(double ratio) => ratio <= dangerAt
      ? AppColors.danger
      : ratio <= warnAt
      ? AppColors.warn
      : AppColors.portal;

  @override
  Widget build(BuildContext context) {
    final target = maxHp == 0 ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: target),
          duration: AppMotion.normal,
          curve: AppMotion.move,
          builder: (context, ratio, _) => Container(
            height: AppSizes.hpBar,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: AppRadius.pillAll,
              border: Border.all(color: AppColors.ink, width: AppOutline.thin),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: ratio,
              // Without it the empty fill box collapses to zero height.
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorFor(ratio),
                  borderRadius: AppRadius.pillAll,
                ),
              ),
            ),
          ),
        ),
        Text(
          '$hp/$maxHp',
          textAlign: TextAlign.center,
          // Readable over the arena art.
          style: AppTypography.caption.copyWith(
            color: AppColors.paper,
            shadows: const [
              Shadow(color: AppColors.ink, offset: AppDepth.shadow),
            ],
          ),
        ),
      ],
    );
  }
}
