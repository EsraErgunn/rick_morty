import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';

/// HP çubuğu (SPEC §4.7): `normal` süresince geçiş yapar; ≤ %50'de sarı, ≤ %20'de kırmızı.
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
              // Bu olmadan boş dolgu kutusu sıfır yüksekliğe çöker.
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
          // Arena görselinin üstünde okunur.
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
