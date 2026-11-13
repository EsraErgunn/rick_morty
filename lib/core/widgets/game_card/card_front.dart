import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../app/theme/card_style.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../cards/game_card_data.dart';
import 'card_art.dart';
import 'card_labels.dart';
import 'featured_art.dart';
import 'rarity_frame_painter.dart';

/// Tasarım boyutunda ön yüz (SPEC §5.5): isim plakası, görsel, tip + nadirlik
/// satırı, 2x2 istatistik, pasif. Çerçeve üstündeki yazı `ink`, gövdedeki `paper`.
///
/// Rick ([FeaturedArt.has]) 2.5D'dir: arka plan ve kesilmiş karakter
/// ayrı katmanlardır; karakter görsel penceresinin üstüne taşar ve kart
/// eğilince arka plandan daha fazla hareket eder ([tilt]).
class CardFront extends StatelessWidget {
  const CardFront({
    required this.data,
    this.hideArt = false,
    this.tilt,
    this.characterOut = false,
    super.key,
  });

  final GameCardData data;

  /// Boş görsel penceresi (öne çıkan giriş: görsel sonradan düşer).
  final bool hideArt;

  /// Öne çıkan paralaks için kart eğimi (null: katmanlar durur).
  final ValueListenable<Offset>? tilt;

  /// 2.5D kart: karakter karttan çıktı (savaş tepkisi); kesilmiş
  /// görsel gizlenir ve pencere kararır.
  final bool characterOut;

  static const double plateHeight = 36;

  /// Kart tasarım birimleri cinsinden görsel penceresi (öne çıkan giriş için).
  static Rect artRect(GameCardData data) {
    final style = RarityStyle.of(data.rarity);
    final body = RarityFramePainter(
      style: style,
      bodyTop: style.frameWidth + plateHeight,
    ).bodyRect(const Size(CardMetrics.designWidth, CardMetrics.designHeight));
    final inner = body.deflate(AppOutline.thin);
    return Rect.fromLTWH(
      inner.left,
      inner.top,
      inner.width,
      body.height * CardMetrics.artShare,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = RarityStyle.of(data.rarity);
    final painter = RarityFramePainter(
      style: style,
      bodyTop: style.frameWidth + plateHeight,
      featured: data.featured,
    );
    final body = painter.bodyRect(
      const Size(CardMetrics.designWidth, CardMetrics.designHeight),
    );
    final passive = l10n.passiveName(data.passive);
    final badgeRoom = data.featured ? CardMetrics.featuredBadge : 0.0;

    return CustomPaint(
      key: ValueKey('card-front-${data.rarity.name}'),
      painter: painter,
      child: Stack(
        // Efsanevi amblem yarısı üst kenarın üstünde durur; gövde önce gelir,
        // böylece öne çıkan karakterin kafası isim plakası yazısının altından geçer.
        clipBehavior: Clip.none,
        children: [
          Positioned.fromRect(
            rect: body.deflate(AppOutline.thin),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(style.notch / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: body.height * CardMetrics.artShare,
                    child: hideArt
                        ? const ColoredBox(
                            key: ValueKey('art-empty'),
                            color: AppColors.ink,
                          )
                        : FeaturedArt.has(data.id)
                        ? FeaturedBackground(
                            data: data,
                            tilt: tilt,
                            empty: characterOut,
                          )
                        : CardArt(
                            url: data.imageUrl,
                            name: data.name,
                            rarity: data.rarity,
                          ),
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
          if (FeaturedArt.has(data.id) && !hideArt && !characterOut) _cutout(),
          Positioned(
            // Öne çıkan rozeti için iki yanda bırakılan boşluk ismi
            // ortada ve rozetten uzak tutar.
            left: style.frameWidth + CardMetrics.padding + badgeRoom,
            right: style.frameWidth + CardMetrics.padding + badgeRoom,
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
          if (data.featured)
            Positioned(
              top:
                  style.frameWidth +
                  (plateHeight - CardMetrics.featuredBadge) / 2,
              right: style.frameWidth + CardMetrics.padding / 2,
              child: Semantics(
                label: AppLocalizations.of(context).featuredBadge,
                child: const FeaturedBadge(),
              ),
            ),
          if (style.emblem)
            const Positioned(
              top: -CardMetrics.emblemSize / 3,
              left: 0,
              right: 0,
              child: Center(child: PortalEmblem()),
            ),
        ],
      ),
    );
  }
}

/// Rick'in kesilmiş görsel katmanını kart ön yüzüne yerleştirir.
extension on CardFront {
  Widget _cutout() {
    final art = CardFront.artRect(data);
    final rect = FeaturedArt.cutoutRect(art);
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: FeaturedCutout(
          key: const ValueKey('featured-cutout'),
          id: data.id,
          window: art.shift(-rect.topLeft),
          tilt: tilt,
        ),
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
            // Nadirlik rengi çerçevede kalır: gövdede küçük yazı olarak
            // epik mor yalnızca 4.10:1 (4.5 gerekir).
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
