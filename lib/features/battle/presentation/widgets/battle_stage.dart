import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/game/battle_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../battle_feedback.dart';
import '../bloc/battle_state.dart';
import 'battle_card_slot.dart';
import 'battle_cues.dart';
import 'event_band.dart';

/// The stage (SPEC §4.7): enemy row on top, event band in the middle,
/// player row at the bottom. Replays [BattleViewState.current] one event at
/// a time and calls [onAdvance] when its animation is done.
class BattleStage extends StatefulWidget {
  const BattleStage({
    required this.state,
    required this.feedback,
    required this.onAdvance,
    required this.onCardTap,
    super.key,
  });

  final BattleViewState state;
  final BattleFeedback feedback;
  final VoidCallback onAdvance;
  final void Function(Side side, int index) onCardTap;

  @override
  State<BattleStage> createState() => _BattleStageState();
}

class _BattleStageState extends State<BattleStage> {
  Timer? _timer;
  int _played = -1;
  final Map<(Side, int), SlotFx> _fx = {};
  BandCue? _band;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePlay());
  }

  @override
  void didUpdateWidget(BattleStage old) {
    super.didUpdateWidget(old);
    _maybePlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _speed => widget.state.fast ? 1 / AppMotion.battleFastFactor : 1.0;

  void _maybePlay() {
    final s = widget.state;
    final event = s.current;
    if (!mounted || s.phase != BattlePhase.replaying || event == null) return;
    if (s.replayTick == _played) return;
    _played = s.replayTick;
    final cue = BattleCues.of(event, AppLocalizations.of(context));
    setState(() {
      _tick++;
      for (final MapEntry(:key, :value) in cue.slots.entries) {
        _fx[key] = SlotFx(
          motion: value.motion,
          tick: _tick,
          popup: value.popup,
        );
      }
      if (cue.band != null) _band = cue.band!.withTick(_tick);
    });
    widget.feedback.event(event);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final wait = reduced ? AppMotion.battleReduced : cue.duration * _speed;
    _timer?.cancel();
    _timer = Timer(wait, widget.onAdvance);
  }

  Widget _row(Side side) {
    final s = widget.state;
    final view = s.view!;
    final cards = side == Side.player ? s.playerCards : s.enemyCards;
    final choosing = s.phase == BattlePhase.choosing;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child:
                BattleCardSlot(
                      key: ValueKey('${side.name}-$i'),
                      card: cards[i],
                      state: view.cards(side)[i],
                      side: side,
                      fx: _fx[(side, i)] ?? const SlotFx(),
                      speed: _speed,
                      selected: side == Side.player && s.selected == i,
                      targetable:
                          choosing &&
                          side == Side.enemy &&
                          s.selected != null &&
                          view.enemy[i].alive,
                      onTap: () => widget.onCardTap(side, i),
                    )
                    .animate(delay: AppMotion.battleDealStagger * i)
                    .then()
                    .custom(
                      duration: reduced
                          ? AppMotion.battleReduced
                          : AppMotion.normal,
                      curve: AppMotion.emerge,
                      builder: (context, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            reduced
                                ? 0
                                : (1 - v) *
                                      AppSizes.battleNumberRise *
                                      (side == Side.player ? 1 : -1),
                          ),
                          child: child,
                        ),
                      ),
                    ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.state;
    final enemyTurn =
        s.phase == BattlePhase.replaying && s.view!.active == Side.enemy;
    final label = enemyTurn
        ? l10n.battleEnemyTurn
        : s.selected == null
        ? l10n.battleYourTurn
        : l10n.battlePickTarget;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        children: [
          _row(Side.enemy),
          Expanded(
            child: EventBand(
              label: label,
              labelColor: enemyTurn ? AppColors.paperMuted : AppColors.paper,
              cue: _band,
              speed: _speed,
            ),
          ),
          _row(Side.player),
        ],
      ),
    );
  }
}
