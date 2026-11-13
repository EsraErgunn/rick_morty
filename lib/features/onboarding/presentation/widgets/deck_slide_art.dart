import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/game/card_type.dart';
import '../../../../core/widgets/game_card/card_labels.dart';
import '../../../../app/theme/card_style.dart';
import '../../../../l10n/app_localizations.dart';
import 'loop_builder.dart';

/// Sayfa 3: tip üçgeni İnsan → Robot → Uzaylı → İnsan; üstünlük
/// üçgen boyunca dolaşır ve ulaştığı tipi yakar.
class DeckSlideArt extends StatelessWidget {
  const DeckSlideArt({super.key});

  static const List<CardType> _cycle = [
    CardType.human,
    CardType.robot,
    CardType.alien,
  ];

  /// Köşeler: üst, sağ alt, sol alt (birim kare).
  static const List<Alignment> _at = [
    Alignment(0, -0.85),
    Alignment(0.85, 0.7),
    Alignment(-0.85, 0.7),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LoopBuilder(
      restAt: 0.5,
      builder: (context, t) {
        final lit = (t * _cycle.length).floor() % _cycle.length;
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ArrowsPainter(_at, t)),
            ),
            for (var i = 0; i < _cycle.length; i++)
              Align(
                alignment: _at[i],
                child: _TypeDisc(
                  icon: CardTypeIcons.of(_cycle[i]),
                  label: l10n.typeName(_cycle[i]),
                  lit: i == (lit + 1) % _cycle.length,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TypeDisc extends StatelessWidget {
  const _TypeDisc({required this.icon, required this.label, required this.lit});

  final IconData icon;
  final String label;
  final bool lit;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedContainer(
        duration: AppMotion.fast,
        width: AppSizes.onboardingTypeDisc,
        height: AppSizes.onboardingTypeDisc,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: lit ? AppColors.portal : AppColors.voidRaised,
          border: Border.all(color: AppColors.ink, width: AppOutline.thick),
        ),
        child: Icon(icon, color: lit ? AppColors.ink : AppColors.paper),
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(label, style: AppTypography.caption),
    ],
  );
}

/// Köşeler arasındaki oklar; bir nokta bunlar boyunca koşar (döngünün her
/// üçte birinde bir kenar).
class _ArrowsPainter extends CustomPainter {
  const _ArrowsPainter(this.at, this.t);

  final List<Alignment> at;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [for (final a in at) a.alongSize(size)];
    final line = Paint()
      ..color = AppColors.paperMuted
      ..strokeWidth = AppOutline.thick
      ..style = PaintingStyle.stroke;
    const inset = AppSizes.onboardingTypeDisc * 0.7;
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      final dir = (b - a) / (b - a).distance;
      final from = a + dir * inset;
      final to = b - dir * inset;
      canvas.drawLine(from, to, line);
      final wing = Offset(-dir.dy, dir.dx) * AppSpacing.xs;
      canvas.drawPath(
        Path()
          ..moveTo(to.dx, to.dy)
          ..lineTo(
            (to - dir * AppSpacing.sm + wing).dx,
            (to - dir * AppSpacing.sm + wing).dy,
          )
          ..moveTo(to.dx, to.dy)
          ..lineTo(
            (to - dir * AppSpacing.sm - wing).dx,
            (to - dir * AppSpacing.sm - wing).dy,
          ),
        line,
      );
    }
    final side = (t * pts.length).floor() % pts.length;
    final f = (t * pts.length) % 1;
    final a = pts[side];
    final b = pts[(side + 1) % pts.length];
    canvas.drawCircle(
      Offset.lerp(a, b, f)!,
      AppSpacing.xs * (0.8 + 0.2 * math.sin(f * math.pi)),
      Paint()..color = AppColors.portalHot,
    );
  }

  @override
  bool shouldRepaint(_ArrowsPainter old) => old.t != t;
}
