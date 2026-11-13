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
import 'fainting.dart';
import 'hp_bar.dart';
import 'slot_motion.dart';

/// What a slot is doing right now (set by the replay, SPEC §4.7).
enum SlotMotion { none, lunge, shake, heavyShake, dodge, revive, victory }

/// A floating number or word above a card.
final class SlotPopup {
  const SlotPopup(this.text, {this.color = AppColors.paper, this.big = false});

  final String text;
  final Color color;
  final bool big;
}

final class SlotFx {
  const SlotFx({
    this.motion = SlotMotion.none,
    this.tick = 0,
    this.popup,
    this.delay = Duration.zero,
  });

  final SlotMotion motion;
  final int tick;
  final SlotPopup? popup;

  /// Start offset (the victory hops run one card after another).
  final Duration delay;
}

/// One card on the stage. Idle: floats and breathes (phases differ per
/// slot). Attack, hit, dodge, revive and victory poses come from
/// [SlotPoses]; faint from [Fainting]. Reduced motion: no movement.
class BattleCardSlot extends StatefulWidget {
  const BattleCardSlot({
    required this.card,
    required this.state,
    required this.side,
    required this.fx,
    required this.speed,
    this.idlePhase = 0,
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

  /// 0..1: where this slot starts in the idle cycle.
  final double idlePhase;
  final bool selected;
  final bool targetable;
  final VoidCallback? onTap;

  @override
  State<BattleCardSlot> createState() => _BattleCardSlotState();
}

class _BattleCardSlotState extends State<BattleCardSlot>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: AppMotion.battleIdle,
  );
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void didUpdateWidget(BattleCardSlot old) {
    super.didUpdateWidget(old);
    final fx = widget.fx;
    if (fx.tick == old.fx.tick || fx.motion == SlotMotion.none) return;
    if (_reduced) return;
    final base = switch (fx.motion) {
      SlotMotion.lunge => AppMotion.battleAttack,
      SlotMotion.shake => AppMotion.battleHit,
      SlotMotion.heavyShake => AppMotion.battleHeavyHit,
      SlotMotion.revive => AppMotion.slow,
      SlotMotion.victory => AppMotion.battleVictory,
      _ => AppMotion.normal,
    };
    _c
      ..duration = (base + fx.delay) * widget.speed
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    _idle.dispose();
    super.dispose();
  }

  /// Progress of the current motion, after its start delay.
  double get _v {
    if (!_c.isAnimating) return 0;
    final total = _c.duration!.inMicroseconds;
    final delay = (widget.fx.delay * widget.speed).inMicroseconds;
    if (total <= delay) return _c.value;
    return ((_c.value * total - delay) / (total - delay)).clamp(0.0, 1.0);
  }

  SlotPose _pose() {
    final v = _v;
    if (v == 0) return SlotPose.rest;
    // The killing blow still shakes; a fainted card does not hop.
    if (!widget.state.alive && widget.fx.motion == SlotMotion.victory) {
      return SlotPose.rest;
    }
    return switch (widget.fx.motion) {
      SlotMotion.lunge => SlotPoses.lunge(v, widget.side),
      SlotMotion.shake => SlotPoses.hit(v, widget.side, heavy: false),
      SlotMotion.heavyShake => SlotPoses.hit(v, widget.side, heavy: true),
      SlotMotion.dodge => SlotPoses.dodge(v),
      SlotMotion.victory => SlotPoses.victory(v),
      _ => SlotPose.rest,
    };
  }

  @override
  Widget build(BuildContext context) {
    final outline = widget.selected
        ? AppColors.portalHot
        : widget.targetable
        ? AppColors.portal
        : AppColors.ink;
    final hitting =
        widget.fx.motion == SlotMotion.shake ||
        widget.fx.motion == SlotMotion.heavyShake;
    final card = AnimatedBuilder(
      animation: Listenable.merge([_c, _idle]),
      builder: (context, child) {
        final v = _v;
        final pose = _pose();
        final wave = math.sin(math.pi * 2 * (_idle.value + widget.idlePhase));
        final alive = widget.state.alive && !_reduced;
        final float = alive ? wave * AppSizes.battleIdleFloat : 0.0;
        final breathe = alive
            ? 1 + (AppMotion.breatheScale - 1) * (0.5 + 0.5 * wave)
            : 1.0;
        final glow = widget.fx.motion == SlotMotion.revive && _c.isAnimating
            ? 1 - v
            : 0.0;
        return Transform.translate(
          offset: Offset(0, float),
          child: Transform(
            alignment: Alignment.center,
            transform: pose.matrix..scaleByDouble(breathe, breathe, 1, 1),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                DecoratedBox(
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
                if (pose.flash > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.cardAll,
                          color: pose.flashColor.withValues(alpha: pose.flash),
                        ),
                      ),
                    ),
                  ),
                if (hitting && v > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: BurstPainter(
                          v: v,
                          heavy: widget.fx.motion == SlotMotion.heavyShake,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      child: Fainting(
        fainted: !widget.state.alive,
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
        .scale(
          begin: const Offset(0.6, 0.6),
          duration: AppMotion.fast * speed,
          curve: AppMotion.popIn,
        )
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
