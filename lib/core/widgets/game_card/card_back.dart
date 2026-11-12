import 'package:flutter/material.dart';

import '../../../app/theme/card_style.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../cards/game_card_data.dart';
import 'game_card.dart';
import 'rarity_frame_painter.dart';

/// Back face (SPEC §5.5): `ink` field with a portal-ring pattern. With
/// [facts] (card detail page) it also lists species, status, origin,
/// location and episode count.
class CardBack extends StatelessWidget {
  const CardBack({this.facts, super.key});

  final GameCardData? facts;

  @override
  Widget build(BuildContext context) => CardSizer(
    child: CustomPaint(
      key: const ValueKey('card-back'),
      painter: const _BackPainter(),
      child: facts == null ? null : _Facts(data: facts!),
    ),
  );
}

class _Facts extends StatelessWidget {
  const _Facts({required this.data});

  final GameCardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = [
      (l10n.cardBackSpecies, data.species),
      (l10n.cardBackStatus, data.status),
      (l10n.cardBackOrigin, data.originName),
      (l10n.cardBackLocation, data.locationName),
      (l10n.cardBackEpisodes, '${data.episodeCount}'),
    ];
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.name, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          for (final (label, value) in rows) ...[
            Text(label, style: AppTypography.caption),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

/// Ink field, concentric portal rings, ink outline.
class _BackPainter extends CustomPainter {
  const _BackPainter();

  static const int _rings = 7;
  static const double _ringAlpha = 0.18;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(AppOutline.thick / 2);
    final shape = cardShape(rect, notch: 0);
    canvas
      ..drawPath(shape, Paint()..color = AppColors.ink)
      ..save()
      ..clipPath(shape);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppOutline.thick * 2
      ..color = AppColors.portal.withValues(alpha: _ringAlpha);
    final center = size.center(Offset.zero);
    final step = size.longestSide / 2 / _rings;
    for (var i = 1; i <= _rings; i++) {
      canvas.drawCircle(center, step * i, ring);
    }
    canvas
      ..drawCircle(
        center,
        CardMetrics.emblemSize,
        Paint()..color = AppColors.portal.withValues(alpha: _ringAlpha * 2),
      )
      ..restore()
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppOutline.thick
          ..color = AppColors.voidRaised,
      );
  }

  @override
  bool shouldRepaint(_BackPainter old) => false;
}
