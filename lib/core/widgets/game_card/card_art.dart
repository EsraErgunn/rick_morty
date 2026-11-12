import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';

/// Builds the art for [url]; replaced in widget tests (no network, no
/// platform cache there).
typedef ArtBuilder = Widget Function(String url, String name);

/// Character artwork: `CachedNetworkImage` with a placeholder and an ink
/// silhouette on error (CLAUDE.md image rule).
class CardArt extends StatelessWidget {
  const CardArt({required this.url, required this.name, super.key});

  final String url;
  final String name;

  /// Test hook: when set, used instead of the network image.
  @visibleForTesting
  static ArtBuilder? debugArtBuilder;

  @override
  Widget build(BuildContext context) {
    final override = debugArtBuilder;
    if (override != null) return override(url, name);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => const ColoredBox(color: AppColors.voidRaised),
      errorWidget: (_, _, _) => InkSilhouette(name: name),
    );
  }
}

/// Offline / missing art: an ink head-and-shoulders shape with the name.
class InkSilhouette extends StatelessWidget {
  const InkSilhouette({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const ValueKey('ink-silhouette'),
    color: AppColors.voidRaised,
    child: Column(
      children: [
        const Expanded(
          child: CustomPaint(
            painter: _SilhouettePainter(),
            size: Size.infinite,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption,
          ),
        ),
      ],
    ),
  );
}

class _SilhouettePainter extends CustomPainter {
  const _SilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.ink;
    final unit = size.shortestSide;
    final cx = size.width / 2;
    canvas
      ..drawCircle(Offset(cx, size.height * 0.4), unit * 0.2, paint)
      ..drawOval(
        Rect.fromCenter(
          center: Offset(cx, size.height * 1.05),
          width: unit * 0.8,
          height: unit * 0.7,
        ),
        paint,
      );
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) => false;
}
