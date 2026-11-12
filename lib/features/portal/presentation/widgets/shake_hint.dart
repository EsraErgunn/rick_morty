import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';

/// "Telefonu salla!" with a rocking hand (SPEC §2.3 AC9, §4.3): three
/// ±15° swings, then a pause, repeat. Reduced motion: static icon.
class ShakeHint extends StatefulWidget {
  const ShakeHint({super.key});

  @override
  State<ShakeHint> createState() => _ShakeHintState();
}

class _ShakeHintState extends State<ShakeHint>
    with SingleTickerProviderStateMixin {
  static const int _swings = 3;
  static const double _maxAngle = 15 * math.pi / 180;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.hintSwing * _swings + AppMotion.hintPause,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _angle(double t) {
    final total = _c.duration!.inMicroseconds;
    final swingPart = (AppMotion.hintSwing * _swings).inMicroseconds / total;
    if (t >= swingPart) return 0;
    final phase = t / swingPart * _swings;
    return math.sin(phase * 2 * math.pi) * _maxAngle;
  }

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('shake-hint'),
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedBuilder(
        animation: _c,
        builder: (context, child) =>
            Transform.rotate(angle: _angle(_c.value), child: child),
        child: const Icon(
          Icons.back_hand,
          size: AppSizes.iconLarge,
          color: AppColors.paper,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        AppLocalizations.of(context).portalShakeHint,
        style: AppTypography.title,
      ),
    ],
  );
}
