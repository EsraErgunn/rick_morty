import 'package:flutter/material.dart';

import '../../../../app/theme/motion.dart';

/// Hafif ölçek döngüsü 1.0 ↔ 1.04 (SPEC §4.2: tek canlandırılmış eylem
/// çağrısı, koleksiyon boşken kullanılır). Azaltılmış harekette kapalı.
class Breathing extends StatefulWidget {
  const Breathing({required this.active, required this.child, super.key});

  final bool active;
  final Widget child;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.breathe,
  );

  bool get _shouldRun =>
      widget.active && !MediaQuery.disableAnimationsOf(context);

  void _sync() {
    if (_shouldRun) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Breathing old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    key: ValueKey(widget.active ? 'breathing-on' : 'breathing-off'),
    scale: Tween(
      begin: 1.0,
      end: AppMotion.breatheScale,
    ).animate(CurvedAnimation(parent: _c, curve: AppMotion.move)),
    child: widget.child,
  );
}
