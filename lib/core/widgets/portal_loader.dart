import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/spacing.dart';

/// The waiting portal: opens from a point (scale 0 → 1, `popIn`), then
/// spins while [active].
///
/// Anti-flicker: if [active] turns false within [AppMotion.loaderShowDelay]
/// the portal never appears; once it appears it stays at least
/// [AppMotion.loaderMinVisible]. [onSettled] fires once the portal is gone
/// (or immediately if it never appeared) after [active] became false.
/// With reduced motion it only fades.
///
/// Week 1 draws a spiral with [CustomPainter]. Week 2 replaces the inside
/// with `portal.frag`; this public API stays the same.
class PortalLoader extends StatefulWidget {
  const PortalLoader({
    required this.active,
    this.intensity = 1,
    this.onSettled,
    this.size = AppSizes.splashPortal,
    super.key,
  });

  final bool active;

  /// 0.0 (dim, e.g. on error) to 1.0 (full).
  final double intensity;
  final VoidCallback? onSettled;
  final double size;

  @override
  State<PortalLoader> createState() => _PortalLoaderState();
}

class _PortalLoaderState extends State<PortalLoader>
    with TickerProviderStateMixin {
  late final AnimationController _appear = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
    reverseDuration: AppMotion.normal,
  );
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: AppMotion.portalSpin,
  );

  Timer? _showTimer;
  Timer? _minTimer;
  bool _visible = false;
  bool _minElapsed = false;
  bool _hidePending = false;
  bool _settled = false;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    if (widget.active) _scheduleShow();
  }

  @override
  void didUpdateWidget(PortalLoader old) {
    super.didUpdateWidget(old);
    if (widget.active == old.active) return;
    if (widget.active) {
      _settled = false;
      _hidePending = false;
      if (!_visible) _scheduleShow();
    } else {
      _requestHide();
    }
  }

  void _scheduleShow() {
    _showTimer?.cancel();
    _showTimer = Timer(AppMotion.loaderShowDelay, _show);
  }

  void _show() {
    if (!mounted || !widget.active) return;
    setState(() => _visible = true);
    _minElapsed = false;
    _minTimer = Timer(AppMotion.loaderMinVisible, () {
      _minElapsed = true;
      if (_hidePending) _hide();
    });
    _appear.forward(from: 0);
    if (!_reduceMotion) _spin.repeat();
  }

  void _requestHide() {
    _showTimer?.cancel();
    if (!_visible) {
      _settle();
    } else if (_minElapsed) {
      _hide();
    } else {
      _hidePending = true;
    }
  }

  Future<void> _hide() async {
    _hidePending = false;
    await _appear.reverse();
    if (!mounted || widget.active) return;
    _spin.stop();
    setState(() => _visible = false);
    _settle();
  }

  /// Reports after the current frame: [onSettled] usually navigates, which
  /// must not happen during build (e.g. from [didUpdateWidget]).
  void _settle() {
    if (_settled) return;
    _settled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.active) widget.onSettled?.call();
    });
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _minTimer?.cancel();
    _appear.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painted = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _PortalPainter(
            turn: _spin.value,
            intensity: widget.intensity.clamp(0, 1),
          ),
        ),
      ),
    );

    final Widget content = !_visible
        ? const SizedBox.shrink()
        : _reduceMotion
        ? FadeTransition(opacity: _appear, child: painted)
        : ScaleTransition(
            scale: CurvedAnimation(
              parent: _appear,
              curve: AppMotion.popIn,
              reverseCurve: AppMotion.move,
            ),
            child: painted,
          );

    return SizedBox.square(
      key: const ValueKey('portal-loader'),
      dimension: widget.size,
      child: Center(child: content),
    );
  }
}

/// Green spiral portal: ink ring, green disc, three hot spiral arms.
class _PortalPainter extends CustomPainter {
  _PortalPainter({required this.turn, required this.intensity});

  /// 0.0 to 1.0, one full rotation.
  final double turn;
  final double intensity;

  static const int _arms = 3;
  static const int _steps = 48;
  static const double _armTurns = 1.25;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - AppOutline.thick;

    final disc = Paint()
      ..color = Color.lerp(AppColors.voidRaised, AppColors.portal, intensity)!;
    canvas.drawCircle(center, radius, disc);

    final arm = Paint()
      ..color = AppColors.portalHot.withValues(alpha: 0.25 + 0.75 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.12;

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(turn * 2 * math.pi);
    for (var a = 0; a < _arms; a++) {
      final start = a * 2 * math.pi / _arms;
      final path = Path()..moveTo(0, 0);
      for (var i = 1; i <= _steps; i++) {
        final t = i / _steps;
        final angle = start + t * _armTurns * 2 * math.pi;
        final r = t * radius * 0.85;
        path.lineTo(r * math.cos(angle), r * math.sin(angle));
      }
      canvas.drawPath(path, arm);
    }
    canvas.restore();

    final ring = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppOutline.thick * 2;
    canvas.drawCircle(center, radius, ring);
  }

  @override
  bool shouldRepaint(_PortalPainter old) =>
      old.turn != turn || old.intensity != intensity;
}
