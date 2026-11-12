import 'package:flutter/material.dart';

import '../../../app/theme/card_style.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../cards/game_card_data.dart';
import 'card_art.dart';
import 'card_labels.dart';
import 'rarity_frame_painter.dart';

/// Front face at design size (SPEC §5.5): name plate, art, type + rarity
/// row, 2x2 stats, passive. Text on the frame is `ink`, on the body `paper`.
class CardFront extends StatelessWidget {
  const CardFront({required this.data, super.key});

  final GameCardData data;

  static const double plateHeight = 36;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = RarityStyle.of(data.rarity);
    final painter = RarityFramePainter(
      style: style,
      bodyTop: style.frameWidth + plateHeight,
    );
    final body = painter.bodyRect(
      const Size(CardMetrics.designWidth, CardMetrics.designHeight),
    );
    final passive = l10n.passiveName(data.passive);

    return CustomPaint(
      key: ValueKey('card-front-${data.rarity.name}'),
      painter: painter,
      child: Stack(
        // The legendary emblem sits half above the top edge.
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: style.frameWidth + CardMetrics.padding,
            right: style.frameWidth + CardMetrics.padding,
            top: style.frameWidth,
            height: plateHeight,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  data.name,
                  maxLines: 1,
                  style: AppTypography.title.copyWith(color: AppColors.ink),
                ),
              ),
            ),
          ),
          if (style.emblem)
            const Positioned(
              top: -CardMetrics.emblemSize / 3,
              left: 0,
              right: 0,
              child: Center(child: PortalEmblem()),
            ),
          Positioned.fromRect(
            rect: body.deflate(AppOutline.thin),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(style.notch / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: body.height * CardMetrics.artShare,
                    child: CardArt(url: data.imageUrl, name: data.name),
                  ),
                  const Divider(
                    height: AppOutline.thin,
                    thickness: AppOutline.thin,
                    color: AppColors.ink,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CardMetrics.padding,
                        vertical: AppSpacing.xxs,
                      ),
                      child: _CardInfo(data: data, passive: passive),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.data, required this.passive});

  final GameCardData data;
  final String? passive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = data.stats;
    Widget stat(String label, int value) => Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption,
          ),
        ),
        Text('$value', style: AppTypography.stat),
      ],
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          children: [
            Icon(
              CardTypeIcons.of(data.type),
              size: CardMetrics.iconSize,
              color: AppColors.paper,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Text(
                l10n.typeName(data.type),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption,
              ),
            ),
            // Rarity color stays on the frame: as small text on the body,
            // epic purple is only 4.10:1 (needs 4.5).
            Text(l10n.rarityName(data.rarity), style: AppTypography.caption),
          ],
        ),
        Row(
          children: [
            Expanded(child: stat(l10n.statHp, s.hp)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: stat(l10n.statAtk, s.atk)),
          ],
        ),
        Row(
          children: [
            Expanded(child: stat(l10n.statDef, s.def)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: stat(l10n.statSpd, s.spd)),
          ],
        ),
        if (passive case final passive?)
          Text(
            passive,
            style: AppTypography.caption.copyWith(color: AppColors.paper),
          ),
      ],
    );
  }
}
