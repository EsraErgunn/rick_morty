import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/card_style.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/cards/game_card_data.dart';
import '../../../../core/game/rarity.dart';
import '../../../../core/widgets/game_card/card_art.dart';
import '../../../../core/widgets/game_card/card_front.dart';
import '../../../../core/widgets/portal/portal_view.dart';
import '../../../../core/widgets/shader_cache.dart';
import '../../../../l10n/app_localizations.dart';
import 'reveal_card.dart';
import 'reveal_effects.dart';
import 'reveal_timeline.dart';

/// Tam açılışın tek karesi (SPEC §4.3): portal, patlama, gölge, ışınlar,
/// hareket eden kart ve dokunma ipucu, mevcut alana göre yerleştirilmiş.
/// Durumsuz: denetleyicilerin sahibi `RevealScene`'dir ve değerlerini aktarır.
class RevealStage extends StatelessWidget {
  const RevealStage({
    required this.timeline,
    required this.t,
    required this.hover,
    required this.rays,
    required this.landed,
    required this.flipping,
    required this.showHint,
    required this.legendary,
    required this.rarity,
    required this.shaders,
    required this.card,
    required this.onTap,
    this.featured,
    this.drop = 0,
    this.showCallout = false,
    super.key,
  });

  final RevealTimeline timeline;

  /// Giriş ilerlemesi 0..1.
  final double t;

  /// Havada sallanma fazı 0..1 (indikten sonra).
  final double hover;

  /// Nadirlik ışınları ilerlemesi 0..1 (çevirmeden sonra).
  final double rays;
  final bool landed;
  final bool flipping;
  final bool showHint;
  final bool legendary;
  final Rarity rarity;
  final ShaderCache shaders;

  /// Çevrilebilir kart (önce arka yüz).
  final Widget card;
  final VoidCallback onTap;

  /// Öne çıkan giriş [GM §12.3]: görseli içine düşen kart.
  final GameCardData? featured;

  /// Görsel düşüşünün 0..1 ilerlemesi.
  final double drop;
  final bool showCallout;

  /// [drop] süresinin düşüşe ayrılan payı; gerisi basılma ve yerleşme.
  static const double _dropFall = 0.6;
  static const double _dropStartScale = 0.4;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      final portalSize = math.min(w * 0.8, h * 0.45);
      final cardW = math.min(AppSizes.revealCard, w * 0.6);
      final cardSize = Size(cardW, cardW / CardMetrics.aspect);
      final from = Offset(w / 2, portalSize / 2);
      final floor = h - AppSpacing.xxl;
      final to = Offset(w / 2, floor - cardSize.height / 2);
      final color = RarityStyle.of(rarity).color;
      final pose = RevealCardPose.at(timeline, t, from: from, to: to);
      final shake = timeline.burst.contains(t)
          ? math.sin(timeline.burst.progress(t) * 3 * 2 * math.pi) *
                AppSizes.screenShake
          : 0.0;
      final intensity = t < timeline.burst.start
          ? PortalIntensity.idle +
                (PortalIntensity.open - PortalIntensity.idle) *
                    timeline.charge.progress(t)
          : (landed ? PortalIntensity.idle : PortalIntensity.open);
      final bob = landed && !flipping
          ? AppSizes.hoverBob * (hover * 2 - 1)
          : 0.0;

      return Transform.translate(
        offset: Offset(shake, 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: from.dx - portalSize / 2,
              top: 0,
              width: portalSize,
              height: portalSize,
              child: PortalView(
                shaders: shaders,
                intensity: intensity,
                legendary: legendary,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: BurstPainter(
                    progress: timeline.burst.progress(t) * 0.999,
                    color: color,
                    center: from,
                  ),
                ),
              ),
            ),
            Positioned(
              left: to.dx - cardSize.width / 2,
              top: floor - AppSpacing.xs,
              width: cardSize.width,
              height: AppSpacing.md,
              child: CustomPaint(
                painter: CardShadowPainter(strength: pose.shadow),
              ),
            ),
            if (rays > 0 && rarity != Rarity.common)
              Positioned(
                left: to.dx - cardSize.width,
                top: to.dy - cardSize.width,
                width: cardSize.width * 2,
                height: cardSize.width * 2,
                child: CustomPaint(
                  painter: RarityRaysPainter(progress: rays, color: color),
                ),
              ),
            if (pose.visible)
              Positioned(
                left: pose.center.dx - cardSize.width / 2,
                top: pose.center.dy - cardSize.height / 2 + bob,
                width: cardSize.width,
                height: cardSize.height,
                child: Transform(
                  alignment: Alignment.center,
                  transform: pose.transform(cardSize),
                  child: GestureDetector(
                    // İçerideki kart dokunuşları yok sayar (yalnızca izin verildiğinde
                    // çevrilir), bu yüzden bu algılayıcı dokunuşları kendisi yakalar.
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: IgnorePointer(child: card),
                  ),
                ),
              ),
            if (featured case final f? when drop > 0 && drop < 1)
              _droppingArt(f, from: from, cardCenter: to, cardSize: cardSize),
            if (featured case final f?)
              Positioned(
                left: 0,
                right: 0,
                top: portalSize + AppSpacing.xs,
                child: AnimatedScale(
                  scale: showCallout ? 1 : 0.6,
                  duration: AppMotion.normal,
                  curve: AppMotion.popIn,
                  child: AnimatedOpacity(
                    opacity: showCallout ? 1 : 0,
                    duration: AppMotion.fast,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppLocalizations.of(context).featuredCallout(f.name),
                        key: const ValueKey('featured-callout'),
                        style: AppTypography.display,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: showHint ? 1 : 0,
                duration: AppMotion.fast,
                child: Text(
                  AppLocalizations.of(context).portalTapToFlip,
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  /// Portaldan görsel penceresine düşen karakter görseli.
  Widget _droppingArt(
    GameCardData card, {
    required Offset from,
    required Offset cardCenter,
    required Size cardSize,
  }) {
    final k = cardSize.width / CardMetrics.designWidth;
    final art = CardFront.artRect(card);
    final target = Rect.fromLTWH(
      cardCenter.dx - cardSize.width / 2 + art.left * k,
      cardCenter.dy - cardSize.height / 2 + art.top * k,
      art.width * k,
      art.height * k,
    );
    final start = Rect.fromCenter(
      center: from,
      width: target.width * _dropStartScale,
      height: target.height * _dropStartScale,
    );
    var rect = target;
    var (sx, sy) = (1.0, 1.0);
    if (drop < _dropFall) {
      rect = Rect.lerp(
        start,
        target,
        AppMotion.fall.transform(drop / _dropFall),
      )!;
    } else {
      (sx, sy) = RevealTimeline.squash((drop - _dropFall) / (1 - _dropFall));
    }
    return Positioned.fromRect(
      rect: rect,
      child: Transform.scale(
        scaleX: sx,
        scaleY: sy,
        alignment: Alignment.bottomCenter,
        child: ClipRect(
          key: const ValueKey('featured-drop'),
          child: CardArt(
            url: card.imageUrl,
            name: card.name,
            rarity: card.rarity,
          ),
        ),
      ),
    );
  }
}
