import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/widgets/game_card/flip_card.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../../../core/widgets/game_card/holo_layer.dart';
import '../../../../core/widgets/portal/portal_view.dart';
import '../../../../core/widgets/shader_cache.dart';
import '../../domain/portal_repository.dart';
import '../portal_feedback.dart';
import 'reveal_card.dart';
import 'reveal_stage.dart';
import 'reveal_timeline.dart';

/// The portal reveal scene (SPEC §4.3, D7). The result is already saved;
/// this only plays it. Reduced motion: a single crossfade.
class RevealScene extends StatefulWidget {
  const RevealScene({
    required this.result,
    required this.shaders,
    required this.feedback,
    required this.onFinished,
    super.key,
  });

  final PortalResult result;
  final ShaderCache shaders;
  final PortalFeedback feedback;

  /// Called once the card is face up and its effect has played.
  final VoidCallback onFinished;

  @override
  State<RevealScene> createState() => _RevealSceneState();
}

class _RevealSceneState extends State<RevealScene>
    with TickerProviderStateMixin {
  late final bool _legendary = widget.result.isLegendary;
  late final RevealTimeline _timeline = RevealTimeline(legendary: _legendary);
  late final AnimationController _intro = AnimationController(vsync: this);
  late final AnimationController _hover = AnimationController(
    vsync: this,
    duration: AppMotion.revealHover,
  );
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final AnimationController _rays = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  /// Featured entrance: the image falls into the empty art window.
  late final bool _featured = widget.result.card.featured;
  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: AppMotion.revealFall + AppMotion.revealSquash * 2,
  );
  late bool _artHidden = _featured;
  bool _showCallout = false;
  final GlobalKey<FlipCardState> _flipKey = GlobalKey();
  final ValueNotifier<Offset> _holoTilt = ValueNotifier(Offset.zero);
  Timer? _hintTimer;
  Timer? _autoFlip;
  double _last = 0;
  bool _landed = false;
  bool _showHint = false;
  bool _flipping = false;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _intro.addListener(_onIntroTick);
    _intro.addStatusListener((s) {
      if (s == AnimationStatus.completed) _onLanded();
    });
    _rays.addListener(() {
      final t = _rays.value;
      _holoTilt.value = Offset(-0.6 + 1.2 * t, 0.3 - 0.6 * t);
    });
    _rays.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onFinished();
    });
    _drop.addStatusListener((s) {
      if (s == AnimationStatus.completed) _onFeatureSettled();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_intro.isAnimating || _intro.value > 0) return;
    _reduced = MediaQuery.disableAnimationsOf(context);
    _intro.duration = _reduced ? AppMotion.revealReduced : _timeline.total;
    widget.feedback.charge();
    unawaited(_intro.forward());
  }

  void _onIntroTick() {
    final t = _intro.value;
    if (_reduced) return;
    for (final beat in _timeline.beatsBetween(_last, t)) {
      switch (beat) {
        case RevealBeat.charge:
          break; // played in didChangeDependencies
        case RevealBeat.burst:
          widget.feedback.burst(legendary: _legendary);
        case RevealBeat.land:
          widget.feedback.land();
      }
    }
    _last = t;
  }

  void _onLanded() {
    if (_reduced) {
      widget.feedback.burst(legendary: _legendary);
      _onFaceUp();
      return;
    }
    setState(() => _landed = true);
    unawaited(_hover.repeat(reverse: true));
    _hintTimer = Timer(AppMotion.revealHintDelay, () {
      if (mounted) setState(() => _showHint = true);
    });
    _autoFlip = Timer(AppMotion.revealAutoFlip, _requestFlip);
  }

  Future<void> _requestFlip() async {
    if (!_landed || _flipping || !mounted) return;
    _autoFlip?.cancel();
    setState(() {
      _flipping = true;
      _showHint = false;
    });
    _hover.stop();
    if (_legendary) await _sweep.forward();
    await _flipKey.currentState?.flip();
  }

  void _onFaceUp() {
    widget.feedback.flip(widget.result.card.rarity);
    if (widget.result.isDuplicate) widget.feedback.duplicateCoins();
    if (_featured && !_reduced) {
      unawaited(_drop.forward());
    } else {
      if (_featured) _onFeatureSettled();
      unawaited(_rays.forward());
    }
  }

  void _onFeatureSettled() {
    widget.feedback.featureSettle();
    setState(() {
      _artHidden = false;
      _showCallout = true;
    });
    if (!_rays.isAnimating && _rays.value == 0) unawaited(_rays.forward());
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _autoFlip?.cancel();
    for (final c in [_intro, _hover, _sweep, _rays, _drop]) {
      c.dispose();
    }
    _holoTilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => _reduced ? _buildReduced(box) : _buildFull(box),
  );

  Widget _card({required bool startOnBack}) {
    final card = widget.result.card;
    return FlipCard(
      key: _flipKey,
      showBack: startOnBack,
      onFlipped: (back) => back ? null : _onFaceUp(),
      front: GameCard(
        data: card,
        hideArt: _artHidden,
        holo: HoloLayer(
          rarity: card.rarity,
          tilt: _holoTilt,
          shaders: widget.shaders,
        ),
      ),
      back: AnimatedBuilder(
        animation: _sweep,
        builder: (context, _) =>
            RevealBack(silhouette: _legendary, sweep: _sweep.value),
      ),
    );
  }

  Widget _buildReduced(BoxConstraints box) {
    final cardW = math.min(AppSizes.revealCard, box.maxWidth * 0.6);
    return Stack(
      alignment: Alignment.center,
      children: [
        FadeTransition(
          opacity: ReverseAnimation(_intro),
          child: SizedBox.square(
            dimension: math.min(box.maxWidth, box.maxHeight) * 0.7,
            child: PortalView(
              shaders: widget.shaders,
              intensity: PortalIntensity.open,
              legendary: _legendary,
            ),
          ),
        ),
        FadeTransition(
          opacity: _intro,
          child: SizedBox(width: cardW, child: _card(startOnBack: false)),
        ),
      ],
    );
  }

  Widget _buildFull(BoxConstraints box) => AnimatedBuilder(
    animation: Listenable.merge([_intro, _hover, _rays, _drop]),
    builder: (context, _) => RevealStage(
      timeline: _timeline,
      t: _intro.value,
      hover: _hover.value,
      rays: _rays.value,
      landed: _landed,
      flipping: _flipping,
      showHint: _showHint,
      legendary: _legendary,
      rarity: widget.result.card.rarity,
      shaders: widget.shaders,
      card: _card(startOnBack: true),
      onTap: _requestFlip,
      featured: _featured ? widget.result.card : null,
      drop: _drop.value,
      showCallout: _showCallout,
    ),
  );
}
