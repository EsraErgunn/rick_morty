import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/card_style.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/cards/game_card_data.dart';
import '../../../../core/widgets/game_card/card_front.dart';
import '../../../../core/widgets/game_card/featured_art.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../../../l10n/app_localizations.dart';

/// Rick'in 2.5D savaş tepkisi, kartının üstüne kart tasarım boyutunda çizilir.
///
/// * Zafer: kesilmiş görsel karttan fırlar, havada döner, büyür
///   ve geri iner; konuşma balonu ve konfeti.
/// * Yenilgi: kesilmiş görsel kartın içine çöker, yana devrilir ve
///   grileşir; konuşma balonu.
///
/// [v] tepkinin ilerlemesidir (0..1), slot tarafından sürülür.
class RickReaction extends StatelessWidget {
  const RickReaction({
    required this.card,
    required this.victory,
    required this.v,
    super.key,
  });

  final GameCardData card;
  final bool victory;
  final double v;

  /// [v]'nin [a, b] aralığındaki kısmı, 0..1.
  static double _seg(double v, double a, double b) =>
      ((v - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    if (v <= 0 || v >= 1) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final rect = FeaturedArt.cutoutRect(CardFront.artRect(card));
    final bubbleIn = _seg(v, 0.15, 0.25) * (1 - _seg(v, 0.9, 0.98));
    final art = CardSizer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (victory)
            Positioned.fill(
              child: CustomPaint(painter: ConfettiPainter(_seg(v, 0.2, 1))),
            ),
          Positioned.fromRect(
            rect: rect,
            child: victory ? _leap(v, card.id) : _collapse(v, card.id),
          ),
        ],
      ),
    );
    // Balon ekran boyutunda yerleştirilir (savaş kartı küçük, tasarım
    // boyutundaki balon okunamazdı), Rick'in kafasının üstünde.
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = box.maxWidth / CardMetrics.designWidth;
          final head = rect.top - (victory ? AppSizes.rickLeap * _lift(v) : 0);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: art),
              if (bubbleIn > 0)
                Positioned(
                  left: box.maxWidth / 2 - AppSizes.rickBubbleWidth / 2,
                  width: AppSizes.rickBubbleWidth,
                  bottom: box.maxHeight - head * scale,
                  child: Opacity(
                    opacity: bubbleIn,
                    child: Transform.scale(
                      scale: AppMotion.popIn.transform(bubbleIn),
                      alignment: Alignment.bottomCenter,
                      child: SpeechBubble(
                        text: victory
                            ? l10n.rickVictoryLine
                            : l10n.rickDefeatLine,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static double _lift(double v) =>
      AppMotion.emerge.transform(_seg(v, 0, 0.3)) *
      (1 - AppMotion.fall.transform(_seg(v, 0.55, 0.8)));

  /// Karttan çık, dön, büyü, in.
  Widget _leap(double v, int id) {
    final lift = _lift(v);
    final spin = AppMotion.move.transform(_seg(v, 0.15, 0.55));
    final grow = math.sin(math.pi * _seg(v, 0, 0.8));
    // Yere değdikten hemen sonra iniş basıklığı.
    final squash = math.sin(math.pi * _seg(v, 0.8, 0.95));
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.translationValues(0, -AppSizes.rickLeap * lift, 0)
        ..rotateZ(math.pi * 2 * spin)
        ..scaleByDouble(
          (1 + AppSizes.rickLeapScale * grow) *
              (1 + AppSizes.battleSquash * squash),
          (1 + AppSizes.rickLeapScale * grow) *
              (1 - AppSizes.battleSquash * squash),
          1,
          1,
        ),
      child: _FadedCutout(id: id),
    );
  }

  /// Kartın içine çök, yana devril, grileş, sol.
  Widget _collapse(double v, int id) {
    final appear = _seg(v, 0, 0.12);
    final sink = AppMotion.fall.transform(_seg(v, 0.2, 0.55));
    final topple = AppMotion.move.transform(_seg(v, 0.45, 0.8));
    final grey = _seg(v, 0.2, 0.7);
    final fade = 1 - _seg(v, 0.82, 1);
    return Opacity(
      opacity: appear * fade,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform:
            Matrix4.translationValues(
                -AppSizes.rickToppleShift * topple,
                AppSizes.rickSink * sink,
                0,
              )
              ..rotateZ(-AppSizes.rickTopple * topple)
              ..scaleByDouble(
                1 + AppSizes.rickSquash * 0.5 * sink,
                1 - AppSizes.rickSquash * sink,
                1,
                1,
              ),
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(_saturation(1 - grey)),
          child: _FadedCutout(id: id),
        ),
      ),
    );
  }

  static List<double> _saturation(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return [
      r * i + s, g * i, b * i, 0, 0, //
      r * i, g * i + s, b * i, 0, 0, //
      r * i, g * i, b * i + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}

/// Alt kısmı soldurulmuş kesilmiş görsel, böylece Rick görsel penceresinden
/// çıkınca sert bir alt kenar görünmez.
class _FadedCutout extends StatelessWidget {
  const _FadedCutout({required this.id});

  final int id;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.ink, AppColors.ink, Colors.transparent],
        stops: [0, 0.7, 1],
      ).createShader(bounds),
      child: FeaturedCutoutImage(id: id),
    ),
  );
}

/// Çizgi roman konuşma balonu: paper dolgu, mürekkep dış çizgi, aşağı bakan bir kuyruk.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _BubblePainter(),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs + AppSizes.rickBubbleTail,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const tail = AppSizes.rickBubbleTail;
    final body = Rect.fromLTWH(0, 0, size.width, size.height - tail);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(AppRadius.button)),
      )
      ..moveTo(size.width / 2 - tail, body.bottom - 1)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + tail, body.bottom - 1)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = AppColors.paper)
      ..drawPath(
        path,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppOutline.thick,
      );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}

/// Karttan yukarı fışkırıp düşen konfeti (bulanıklık yok, düz parçalar).
/// Konumlar her parça için sabittir (altın açı yayılımı), böylece her zafer
/// aynı görünür ve `Random` gerekmez.
class ConfettiPainter extends CustomPainter {
  const ConfettiPainter(this.t);

  /// Tepki boyunca 0..1.
  final double t;

  static const int _count = 36;
  static const double _goldenAngle = 2.39996;
  static const List<Color> _colors = [
    AppColors.portal,
    AppColors.portalHot,
    AppColors.rarityLegendary,
    AppColors.rarityRare,
    AppColors.rarityEpic,
    AppColors.warn,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final origin = Offset(size.width / 2, size.height * 0.3);
    final burst = AppMotion.emerge.transform((t / 0.3).clamp(0.0, 1.0));
    final fall = t * t * AppSizes.confettiFall;
    final alpha = 1 - ((t - 0.75) / 0.25).clamp(0.0, 1.0);
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final a = i * _goldenAngle;
      final r = AppSizes.confettiSpread * (0.4 + 0.6 * ((i * 7) % 11) / 10);
      final p =
          origin +
          Offset(
            math.cos(a) * r * burst,
            math.sin(a) * r * 0.6 * burst - r * 0.5 * burst,
          ) +
          Offset(0, fall);
      paint.color = _colors[i % _colors.length].withValues(alpha: alpha);
      canvas
        ..save()
        ..translate(p.dx, p.dy)
        ..rotate(a + t * math.pi * 4)
        ..drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: AppSizes.confettiSize,
            height: AppSizes.confettiSize * 0.5,
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => old.t != t;
}
