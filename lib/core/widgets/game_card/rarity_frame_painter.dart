import 'package:flutter/material.dart';

import '../../../app/theme/card_style.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';

/// Card outline: rounded corners, or notched corners for epic/legendary.
Path cardShape(Rect rect, {required double notch}) {
  if (notch <= 0) {
    return Path()..addRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.card)),
    );
  }
  return Path()
    ..moveTo(rect.left + notch, rect.top)
    ..lineTo(rect.right - notch, rect.top)
    ..lineTo(rect.right, rect.top + notch)
    ..lineTo(rect.right, rect.bottom - notch)
    ..lineTo(rect.right - notch, rect.bottom)
    ..lineTo(rect.left + notch, rect.bottom)
    ..lineTo(rect.left, rect.bottom - notch)
    ..lineTo(rect.left, rect.top + notch)
    ..close();
}

/// Paints the rarity frame (SPEC §5.5): colored band with an ink outline,
/// the body area in `voidRaised`, and the rare inner `paper` line.
/// [bodyTop] is where the body starts (below the name plate).
class RarityFramePainter extends CustomPainter {
  const RarityFramePainter({required this.style, required this.bodyTop});

  final RarityStyle style;
  final double bodyTop;

  Rect bodyRect(Size size) => Rect.fromLTRB(
    style.frameWidth,
    bodyTop,
    size.width - style.frameWidth,
    size.height - style.frameWidth,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final outer = (Offset.zero & size).deflate(AppOutline.thick / 2);
    final shape = cardShape(outer, notch: style.notch);

    canvas.drawPath(shape, Paint()..color = style.color);

    final body = bodyRect(size);
    final bodyShape = cardShape(body, notch: style.notch / 2);
    canvas.drawPath(bodyShape, Paint()..color = AppColors.voidRaised);
    if (style.innerLine) {
      canvas.drawPath(
        cardShape(
          body.inflate(CardMetrics.innerLineWidth),
          notch: style.notch / 2,
        ),
        Paint()
          ..color = AppColors.paper
          ..style = PaintingStyle.stroke
          ..strokeWidth = CardMetrics.innerLineWidth,
      );
    }
    canvas
      ..drawPath(
        bodyShape,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppOutline.thin,
      )
      ..drawPath(
        shape,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppOutline.thick,
      );
  }

  @override
  bool shouldRepaint(RarityFramePainter old) =>
      old.style != style || old.bodyTop != bodyTop;
}

/// Legendary emblem: a small portal ring (SPEC §5.5).
class PortalEmblem extends StatelessWidget {
  const PortalEmblem({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('legendary-emblem'),
    width: CardMetrics.emblemSize,
    height: CardMetrics.emblemSize,
    decoration: BoxDecoration(
      color: AppColors.portal,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.ink, width: AppOutline.thick),
      boxShadow: const [
        BoxShadow(color: AppColors.portalHot, spreadRadius: -6),
      ],
    ),
  );
}
