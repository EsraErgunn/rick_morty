import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import 'battle_cues.dart';

/// Middle band: the turn label and the latest callout (pops in, then fades).
class EventBand extends StatelessWidget {
  const EventBand({
    required this.label,
    required this.labelColor,
    required this.cue,
    required this.speed,
    super.key,
  });

  final String label;
  final Color labelColor;
  final BandCue? cue;
  final double speed;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: AppMotion.fast,
          child: Text(
            label,
            key: ValueKey(label),
            textAlign: TextAlign.center,
            style: AppTypography.label.copyWith(color: labelColor),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: AppTypography.calloutSize * 1.3,
          child: switch (cue) {
            null => const SizedBox.shrink(),
            final c => _Callout(
              key: ValueKey('band-${c.tick}'),
              cue: c,
              speed: speed,
              reduced: reduced,
            ),
          },
        ),
      ],
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.cue,
    required this.speed,
    required this.reduced,
    super.key,
  });

  final BandCue cue;
  final double speed;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final style = (cue.small ? AppTypography.title : AppTypography.callout)
        .copyWith(
          color: cue.color,
          shadows: const [
            Shadow(color: AppColors.ink, offset: AppDepth.shadow),
          ],
        );
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(cue.text, style: style, textAlign: TextAlign.center),
    );
    if (reduced) {
      return text
          .animate()
          .fadeIn(duration: AppMotion.battleReduced)
          .then(delay: AppMotion.slow)
          .fadeOut(duration: AppMotion.battleReduced);
    }
    return text
        .animate()
        .scale(
          begin: const Offset(0.4, 0.4),
          duration: AppMotion.slow * speed,
          curve: cue.elastic ? AppMotion.reward : AppMotion.popIn,
        )
        .fadeIn(duration: AppMotion.fast * speed)
        .then(delay: AppMotion.normal * speed)
        .fadeOut(duration: AppMotion.normal * speed);
  }
}
