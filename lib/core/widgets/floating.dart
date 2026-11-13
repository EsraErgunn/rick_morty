import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/motion.dart';
import '../../app/theme/spacing.dart';

/// Izgaralardaki kartlar (koleksiyon, deste) için hafif aşağı-yukarı süzülme. [phase]
/// (0..1) komşuları kaydırır, böylece ızgara asla aynı anda hareket etmez.
/// Azaltılmış harekette sabit durur.
class Floating extends StatefulWidget {
  const Floating({required this.child, this.phase = 0, super.key});

  final Widget child;
  final double phase;

  /// Komşu ızgara hücreleri için farklı olan bir faz.
  static double phaseFor(int index) => (index * 0.37) % 1;

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.gridFloat,
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.translate(
      offset: Offset(
        0,
        AppSizes.gridFloat * math.sin(math.pi * 2 * (_c.value + widget.phase)),
      ),
      child: child,
    ),
    child: widget.child,
  );
}
