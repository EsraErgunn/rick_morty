import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/motion.dart';

/// Tap to flip between [front] and [back]: Y rotation with perspective,
/// faces swap at 90° so only one is ever visible (animation rules).
/// With reduced motion the faces swap instantly.
///
/// Week 1 is silent; Week 2 adds sound + haptic from a `BlocListener` /
/// [onFlipped] (no change here).
class FlipCard extends StatefulWidget {
  const FlipCard({
    required this.front,
    required this.back,
    this.onFlipped,
    this.showBack = false,
    super.key,
  });

  final Widget front;
  final Widget back;

  /// Called when a flip finishes; `true` when the back is now showing.
  final ValueChanged<bool>? onFlipped;

  /// Starting face.
  final bool showBack;

  @override
  State<FlipCard> createState() => FlipCardState();
}

class FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
    value: widget.showBack ? 1 : 0,
  );
  late final Animation<double> _turn = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.move,
  );

  bool get showingBack => _controller.value >= 0.5;

  /// Flips to the other face.
  Future<void> flip() async {
    final toBack = _controller.value < 0.5;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = toBack ? 1 : 0;
    } else if (toBack) {
      await _controller.forward();
    } else {
      await _controller.reverse();
    }
    if (mounted) widget.onFlipped?.call(toBack);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: flip,
    child: AnimatedBuilder(
      animation: _turn,
      builder: (context, _) {
        final angle = _turn.value * math.pi;
        final backVisible = angle > math.pi / 2;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, AppMotion.perspective)
          ..rotateY(backVisible ? angle - math.pi : angle);
        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: backVisible
              ? KeyedSubtree(
                  key: const ValueKey('flip-back'),
                  child: widget.back,
                )
              : KeyedSubtree(
                  key: const ValueKey('flip-front'),
                  child: widget.front,
                ),
        );
      },
    ),
  );
}
