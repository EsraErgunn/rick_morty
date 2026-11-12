import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/game/battle_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../battle_feedback.dart';
import '../bloc/battle_bloc.dart';
import '../bloc/battle_event.dart';
import '../bloc/battle_state.dart';
import '../widgets/battle_result_view.dart';
import '../widgets/battle_stage.dart';
import '../widgets/pre_battle_view.dart';
import '../../../../core/widgets/app_back_button.dart';

/// Battle (SPEC §2.7, §4.7). Expects a [BattleBloc] above it.
class BattlePage extends StatefulWidget {
  const BattlePage({
    required this.feedback,
    required this.onExit,
    required this.onGoToDeck,
    super.key,
  });

  final BattleFeedback feedback;
  final VoidCallback onExit;
  final VoidCallback onGoToDeck;

  @override
  State<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage> {
  @override
  void initState() {
    super.initState();
    widget.feedback.enter();
  }

  @override
  void dispose() {
    widget.feedback.leave();
    super.dispose();
  }

  static bool _playing(BattleViewState s) =>
      s.phase == BattlePhase.choosing || s.phase == BattlePhase.replaying;

  Future<void> _confirmLeave(BuildContext context) async {
    final bloc = context.read<BattleBloc>();
    if (!_playing(bloc.state)) {
      widget.onExit();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.battleLeaveTitle),
        content: Text(l10n.battleLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.battleLeaveCancel),
          ),
          FilledButton(
            key: const ValueKey('battle-leave-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.battleLeaveConfirm),
          ),
        ],
      ),
    );
    if (leave ?? false) bloc.add(const BattleLeft());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<BattleBloc>();
    return BlocConsumer<BattleBloc, BattleViewState>(
      listenWhen: (a, b) => !a.left && b.left,
      listener: (context, state) => widget.onExit(),
      builder: (context, state) => PopScope(
        canPop: !_playing(state),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmLeave(context);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.battleTitle),
            leading: AppBackButton(
              key: const ValueKey('battle-leave'),
              onFeedback: widget.feedback.select,
              onPressed: () => _confirmLeave(context),
            ),
            actions: [
              if (_playing(state))
                TextButton(
                  key: const ValueKey('battle-speed'),
                  onPressed: () => bloc.add(const BattleSpeedToggled()),
                  child: Text(
                    l10n.battleSpeed,
                    style: AppTypography.label.copyWith(
                      decoration: state.fast ? TextDecoration.underline : null,
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: switch (state.phase) {
              BattlePhase.loading => const SizedBox.shrink(),
              BattlePhase.noDeck => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.battleNoDeck,
                        textAlign: TextAlign.center,
                        style: AppTypography.body,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: widget.onGoToDeck,
                        child: Text(l10n.battleGoToDeck),
                      ),
                    ],
                  ),
                ),
              ),
              BattlePhase.preBattle => PreBattleView(
                state: state,
                onStart: () {
                  widget.feedback.select();
                  bloc.add(const BattleStartPressed());
                },
              ),
              BattlePhase.choosing || BattlePhase.replaying => BattleStage(
                state: state,
                feedback: widget.feedback,
                onAdvance: () => bloc.add(const BattleReplayAdvanced()),
                onCardTap: (side, i) {
                  if (state.inputBlocked) return;
                  if (!state.view!.cards(side)[i].alive) return;
                  if (side == Side.enemy && state.selected == null) return;
                  widget.feedback.select();
                  bloc.add(BattleCardTapped(side, i));
                },
              ),
              BattlePhase.finished => BattleResultView(
                result: state.result ?? BattleResult.defeat,
                reward: state.reward,
                onAgain: () {
                  widget.feedback.select();
                  bloc.add(const BattleOpened());
                },
                onExit: widget.onExit,
                onCoinTick: widget.feedback.coinTick,
              ),
            },
          ),
        ),
      ),
    );
  }
}
