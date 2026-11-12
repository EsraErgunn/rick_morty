import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/spacing.dart';
import '../../../../core/game/economy.dart';
import '../../../../core/sensors/shake_detector.dart';
import '../../../../core/widgets/coin_counter.dart';
import '../../../../core/widgets/portal/portal_view.dart';
import '../../../../core/widgets/shader_cache.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/portal_bloc.dart';
import '../bloc/portal_event.dart';
import '../bloc/portal_state.dart';
import '../portal_feedback.dart';
import '../widgets/portal_result_view.dart';
import '../widgets/shake_hint.dart';
import '../../../../core/widgets/app_back_button.dart';

/// Portal screen (SPEC §2.3, §5.6). Expects a [PortalBloc] above it.
/// Shake is listened to only while this page is shown and the app is in
/// the foreground (AC7); the button is the fallback.
class PortalPage extends StatefulWidget {
  const PortalPage({
    required this.shaders,
    required this.shake,
    required this.feedback,
    required this.deckReady,
    required this.onGoToBattle,
    required this.onGoToCollection,
    super.key,
  });

  final ShaderCache shaders;
  final ShakeDetector shake;
  final PortalFeedback feedback;

  /// "Savaşa git" is offered only with a full deck (SPEC §2.3 AC2).
  final bool deckReady;
  final VoidCallback onGoToBattle;
  final VoidCallback onGoToCollection;

  @override
  State<PortalPage> createState() => _PortalPageState();
}

class _PortalPageState extends State<PortalPage> with WidgetsBindingObserver {
  StreamSubscription<void>? _shakeSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final bloc = context.read<PortalBloc>();
    _shakeSub = widget.shake.shakes.listen(
      (_) => bloc.add(const PortalShaken()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.shake.resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      widget.shake.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_shakeSub?.cancel());
    super.dispose();
  }

  void _onState(BuildContext context, PortalState state) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (state.failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.portalError)));
      return;
    }
    widget.feedback.notEnoughCoins();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.portalNotEnoughCoins(EconomyRules.portalCost)),
        action: widget.deckReady
            ? SnackBarAction(
                label: l10n.portalGoToBattle,
                onPressed: widget.onGoToBattle,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<PortalBloc, PortalState>(
      listenWhen: (a, b) =>
          a.notEnoughCoins != b.notEnoughCoins ||
          (b.failure != null && a.failure != b.failure),
      listener: _onState,
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          leading: AppBackButton(onFeedback: widget.feedback.button),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.gutter),
              child: CoinCounter(
                coins: state.coins,
                shakeTick: state.notEnoughCoins,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: switch (state.result) {
              final result? when state.phase != PortalPhase.idle =>
                PortalResultView(
                  key: ValueKey(result),
                  result: result,
                  shaders: widget.shaders,
                  feedback: widget.feedback,
                  revealed: state.phase == PortalPhase.revealed,
                  onFinished: () =>
                      context.read<PortalBloc>().add(const RevealFinished()),
                  onOpenAgain: () =>
                      context.read<PortalBloc>().add(const PortalReset()),
                  onGoToCollection: widget.onGoToCollection,
                ),
              _ => _IdlePortal(
                state: state,
                shaders: widget.shaders,
                onOpen: () {
                  widget.feedback.button();
                  context.read<PortalBloc>().add(const PortalOpenRequested());
                },
                buttonLabel: l10n.portalOpenButton(EconomyRules.portalCost),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _IdlePortal extends StatelessWidget {
  const _IdlePortal({
    required this.state,
    required this.shaders,
    required this.onOpen,
    required this.buttonLabel,
  });

  final PortalState state;
  final ShaderCache shaders;
  final VoidCallback onOpen;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.portalHero,
              maxHeight: AppSizes.portalHero,
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: PortalView(
                shaders: shaders,
                intensity: state.phase == PortalPhase.opening
                    ? PortalIntensity.open
                    : PortalIntensity.idle,
              ),
            ),
          ),
        ),
      ),
      if (state.showShakeHint) ...[
        const ShakeHint(),
        const SizedBox(height: AppSpacing.lg),
      ],
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          key: const ValueKey('portal-open-button'),
          onPressed: state.busy ? null : onOpen,
          child: Text(buttonLabel),
        ),
      ),
    ],
  );
}
