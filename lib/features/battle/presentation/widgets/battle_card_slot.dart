import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/cards/game_card_data.dart';
import '../../../../core/game/battle_model.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import 'hp_bar.dart';

/// What a slot is doing right now (set by the replay, SPEC §4.7).
enum SlotMotion { none, lunge, shake, dodge, revive }

/// A floating number or word above a card.
final class SlotPopup {
  const SlotPopup(this.text, {this.color = AppColors.paper, this.big = false});

  final String text;
  final Color color;
  final bool big;
}

final class SlotFx {
  const SlotFx({this.motion = SlotMotion.none, this.tick = 0, this.popup});

  final SlotMotion motion;
  final int tick;
  final SlotPopup? popup;
}

/// One card on the stage: lift when selected, outline when targetable,
/// lunge / shake / sidestep / revive glow, faint (grey, tilt, drop), HP bar.
class BattleCardSlot extends StatefulWidget {
  const BattleCardSlot({
    required this.card,
    required this.state,
    required this.side,
    required this.fx,
    required this.speed,
    this.selected = false,
    this.targetable = false,
    this.onTap,
    super.key,
  });

  final GameCardData card;
  final BattleCard state;
  final Side side;
  final SlotFx fx;

  /// Duration multiplier (1, ½ for 2×).
  final double speed;
  final bool selected;
  final bool targetable;
  final VoidCallback? onTap;

  @override
  State<BattleCardSlot> createState() => _BattleCardSlotState();
}

class _BattleCardSlotState extends State<BattleCardSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  static const int _shakeWaves = 3;

  @override
  void didUpdateWidget(BattleCardSlot old) {
    super.didUpdateWidget(old);
    final fx = widget.fx;
    if (fx.tick == old.fx.tick || fx.motion == SlotMotion.none) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    final base = switch (fx.motion) {
      SlotMotion.shake => AppMotion.fast,
      SlotMotion.revive => AppMotion.slow,
      _ => AppMotion.normal,
    };
    _c
      ..duration = base * widget.speed
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Offset _motionOffset(double v) {
    final dir = widget.side == Side.player ? -1.0 : 1.0;
    return switch (widget.fx.motion) {
      SlotMotion.lunge => Offset(
        0,
        dir *
            AppSizes.battleLunge *
            math.sin(math.pi * AppMotion.move.transform(v)),
      ),
      SlotMotion.shake => Offset(
        AppSizes.screenShake *
            math.sin(v * math.pi * 2 * _shakeWaves) *
            (1 - v),
        0,
      ),
      SlotMotion.dodge => Offset(
        AppSizes.battleLunge * math.sin(math.pi * v),
        0,
      ),
      _ => Offset.zero,
    };
  }

  @override
  Widget build(BuildContext context) {
    final fainted = !widget.state.alive;
    final outline = widget.selected
        ? AppColors.portalHot
        : widget.targetable
        ? AppColors.portal
        : AppColors.ink;
    final card = AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = _c.isAnimating ? _c.value : 0.0;
        final glow = widget.fx.motion == SlotMotion.revive && _c.isAnimating
            ? 1 - v
            : 0.0;
        return Transform.translate(
          offset: _motionOffset(v),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardAll,
              border: Border.all(
                color: Color.lerp(outline, AppColors.portal, glow)!,
                width: outline == AppColors.ink && glow == 0
                    ? AppOutline.thin
                    : AppOutline.thick + AppOutline.thin * glow,
              ),
            ),
            child: child,
          ),
        );
      },
      child: _Fainting(
        fainted: fainted,
        speed: widget.speed,
        child: GameCard(data: widget.card),
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.move,
        transform: Matrix4.translationValues(
          0,
          widget.selected ? -AppSizes.battleLift : 0,
          0,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                card,
                const SizedBox(height: AppSpacing.xxs),
                HpBar(hp: widget.state.hp, maxHp: widget.state.maxHp),
              ],
            ),
            if (widget.fx.popup case final popup?)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    key: ValueKey('popup-${widget.fx.tick}'),
                    child: _Popup(popup: popup, speed: widget.speed),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Damage / heal number: floats up and fades (`slow`).
class _Popup extends StatelessWidget {
  const _Popup({required this.popup, required this.speed});

  final SlotPopup popup;
  final double speed;

  @override
  Widget build(BuildContext context) {
    final style = (popup.big ? AppTypography.display : AppTypography.headline)
        .copyWith(
          color: popup.color,
          shadows: const [
            Shadow(color: AppColors.ink, offset: AppDepth.shadow),
          ],
        );
    final text = Text(popup.text, style: style, textAlign: TextAlign.center);
    if (MediaQuery.disableAnimationsOf(context)) return text;
    return text
        .animate()
        .moveY(
          end: -AppSizes.battleNumberRise,
          duration: AppMotion.slow * speed,
          curve: AppMotion.emerge,
        )
        .fadeOut(
          delay: AppMotion.normal * speed,
          duration: AppMotion.normal * speed,
        );
  }
}

/// Fainted card: desaturates, tilts and drops (`slow`); reverses on revive.
class _Fainting extends StatelessWidget {
  const _Fainting({
    required this.fainted,
    required this.speed,
    required this.child,
  });

  final bool fainted;
  final double speed;
  final Widget child;

  static const double _fadeTo = 0.45;

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

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: fainted ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? AppMotion.battleReduced
        : AppMotion.slow * speed,
    curve: AppMotion.fall,
    builder: (context, f, child) => Opacity(
      opacity: 1 - (1 - _fadeTo) * f,
      child: Transform.translate(
        offset: Offset(0, AppSizes.battleFaintDrop * f),
        child: Transform.rotate(
          angle: AppSizes.battleFaintTilt * f,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(_saturation(1 - f)),
            child: child,
          ),
        ),
      ),
    ),
    child: child,
  );
}
