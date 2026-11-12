import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../l10n/app_localizations.dart';

/// Coin balance (tabular). Rolls to a new value (`slow`, `elasticOut`,
/// SPEC §4.2) and shakes on the X axis whenever [shakeTick] changes
/// (not enough coins, SPEC §4.3).
class CoinCounter extends StatefulWidget {
  const CoinCounter({required this.coins, this.shakeTick = 0, super.key});

  final int coins;
  final int shakeTick;

  @override
  State<CoinCounter> createState() => _CoinCounterState();
}

class _CoinCounterState extends State<CoinCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: AppMotion.coinShake,
  );

  static const int _shakeCycles = 3;

  @override
  void didUpdateWidget(CoinCounter old) {
    super.didUpdateWidget(old);
    if (widget.shakeTick != old.shakeTick &&
        !MediaQuery.disableAnimationsOf(context)) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).coinsLabel(widget.coins);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          final t = _shake.value;
          final dx =
              math.sin(t * _shakeCycles * 2 * math.pi) *
              AppSizes.coinShake *
              (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.toll,
              color: AppColors.portal,
              size: AppSizes.iconSmall,
            ),
            const SizedBox(width: AppSpacing.xxs),
            TweenAnimationBuilder<double>(
              tween: Tween(end: widget.coins.toDouble()),
              duration: AppMotion.slow,
              curve: AppMotion.reward,
              builder: (context, value, _) => Text(
                '${value.round().clamp(0, 1 << 31)}',
                key: const ValueKey('coin-value'),
                style: AppTypography.coin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
