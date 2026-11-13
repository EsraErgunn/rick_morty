import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../game/rarity.dart';
import '../shader_cache.dart';

/// Kart yüzü üstünde holo folyo. Gücü nadirlikten gelir [GM §2];
/// sıradan (0) hiçbir şey çizmez. [tilt] 3D eğimle aynı değerdir
/// (`TiltingGameCard`), böylece ikisi birlikte hareket eder. Yalnızca eğim
/// değişince yeniden çizilir. `holo.frag` kullanır; shader
/// yüklenemezse sabit bir çapraz parlama.
class HoloLayer extends StatefulWidget {
  const HoloLayer({
    required this.rarity,
    required this.tilt,
    required this.shaders,
    super.key,
  });

  final Rarity rarity;
  final ValueListenable<Offset> tilt;
  final ShaderCache shaders;

  @override
  State<HoloLayer> createState() => _HoloLayerState();
}

class _HoloLayerState extends State<HoloLayer> {
  /// Katman başına bir shader örneği, bir kez oluşturulur ve katmanla birlikte atılır.
  /// Sıradan kartlar (güç 0) asla oluşturmaz.
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    if (widget.rarity.holoStrength > 0) {
      _shader = widget.shaders.holo?.fragmentShader();
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strength = widget.rarity.holoStrength;
    if (strength == 0) return const SizedBox.shrink();
    final shader = _shader;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          key: ValueKey(shader == null ? 'holo-fallback' : 'holo-shader'),
          size: Size.infinite,
          painter: shader == null
              ? _FallbackSheenPainter(strength: strength)
              : _HoloShaderPainter(
                  shader: shader,
                  tilt: widget.tilt,
                  strength: strength,
                ),
        ),
      ),
    );
  }
}

class _HoloShaderPainter extends CustomPainter {
  _HoloShaderPainter({
    required this.shader,
    required this.tilt,
    required this.strength,
  }) : super(repaint: tilt);

  final ui.FragmentShader shader;
  final ValueListenable<Offset> tilt;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final t = tilt.value;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, t.dx)
      ..setFloat(3, t.dy)
      ..setFloat(4, strength);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.plus,
    );
  }

  @override
  bool shouldRepaint(_HoloShaderPainter old) =>
      old.strength != strength || old.shader != shader;
}

/// Shader'sız yedek: sabit bir çapraz parlama, nadir kartlarda daha güçlü.
class _FallbackSheenPainter extends CustomPainter {
  const _FallbackSheenPainter({required this.strength});

  final double strength;

  static const double _maxAlpha = 0.25;

  @override
  void paint(Canvas canvas, Size size) {
    final white = Colors.white.withValues(alpha: _maxAlpha * strength);
    final clear = white.withValues(alpha: 0);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [clear, white, clear],
      stops: const [0.35, 0.5, 0.65],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = gradient.createShader(Offset.zero & size)
        ..blendMode = BlendMode.plus,
    );
  }

  @override
  bool shouldRepaint(_FallbackSheenPainter old) => old.strength != strength;
}
