import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/motion.dart';

/// [front] ile [back] arasında çevirmek için dokun: perspektifli Y dönüşü,
/// yüzler 90°'de değişir, böylece hep yalnızca biri görünür (animasyon kuralları).
/// Azaltılmış harekette yüzler anında değişir.
///
/// 1. hafta sessizdir; 2. hafta bir `BlocListener` / [onFlipped] ile ses + titreşim
/// ekler (burada değişiklik yok).
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

  /// Çevirme bitince çağrılır; arka yüz görünüyorsa `true`.
  final ValueChanged<bool>? onFlipped;

  /// Başlangıç yüzü.
  final bool showBack;

  @override
  State<FlipCard> createState() => FlipCardState();
}

/// [FlipCard]'ın durumu; açılış sahnesi kartı GlobalKey ile [flip] ederek çevirebilsin diye açık.
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

  /// Diğer yüze çevirir.
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
