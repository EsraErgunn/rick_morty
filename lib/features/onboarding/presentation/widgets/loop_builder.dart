import 'package:flutter/material.dart';

import '../../../../app/theme/motion.dart';

/// Repeats [AppMotion.onboardingLoop] and builds with its progress (0..1).
/// Reduced motion: no loop, [restAt] is used.
class LoopBuilder extends StatefulWidget {
  const LoopBuilder({required this.builder, this.restAt = 0, super.key});

  final Widget Function(BuildContext context, double t) builder;
  final double restAt;

  @override
  State<LoopBuilder> createState() => _LoopBuilderState();
}

class _LoopBuilderState extends State<LoopBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.onboardingLoop,
  );
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
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
  Widget build(BuildContext context) => RepaintBoundary(
    child: _reduced
        ? widget.builder(context, widget.restAt)
        : AnimatedBuilder(
            animation: _c,
            builder: (context, _) => widget.builder(context, _c.value),
          ),
  );
}
