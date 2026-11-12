import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/motion.dart';
import '../../app/theme/spacing.dart';
import 'portal/portal_spiral_painter.dart';
import 'portal/portal_view.dart';
import 'shader_cache.dart';

/// The waiting portal: opens from a point (scale 0 → 1, `popIn`), then
/// spins while [active].
///
/// Anti-flicker: if [active] turns false within [AppMotion.loaderShowDelay]
/// the portal never appears; once it appears it stays at least
/// [AppMotion.loaderMinVisible]. [onSettled] fires once the portal is gone
/// (or immediately if it never appeared) after [active] became false.
/// With reduced motion it only fades.
///
/// The inside is the `portal.frag` vortex ([PortalView], SPEC D8) when
/// [shaders] is given, otherwise the spiral painter (fallback and tests).
class PortalLoader extends StatefulWidget {
  const PortalLoader({
    required this.active,
    this.intensity = 1,
    this.onSettled,
    this.size = AppSizes.splashPortal,
    this.shaders,
    super.key,
  });

  final bool active;

  /// 0.0 (dim, e.g. on error) to 1.0 (full).
  final double intensity;
  final VoidCallback? onSettled;
  final double size;

  /// Shader cache for the vortex; null = spiral painter.
  final ShaderCache? shaders;

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
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (mounted && !widget.active) widget.onSettled?.call();
      })
      // A post-frame callback needs a frame; make sure one comes.
      ..scheduleFrame();
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
    final cache = widget.shaders;
    final Widget painted = cache != null
        ? SizedBox.square(
            dimension: widget.size,
            child: PortalView(shaders: cache, intensity: widget.intensity),
          )
        : RepaintBoundary(
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, _) => CustomPaint(
                size: Size.square(widget.size),
                painter: PortalSpiralPainter(
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
