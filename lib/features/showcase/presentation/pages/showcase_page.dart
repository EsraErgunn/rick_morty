import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/audio/audio_assets.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/cards/game_card_data.dart';
import '../../../../core/feedback/ui_feedback.dart';
import '../../../../core/sensors/tilt_stream.dart';
import '../../../../core/widgets/portal_loader.dart';
import '../../../../core/widgets/screen_background.dart';
import '../../../../core/widgets/shader_cache.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/falling_card.dart';

/// Açılış vitrini: her açılışta menüden önce Rick'in 2.5D kartı gösterilir.
/// Kart küçük bir portaldan düşer, telefon eğilince hareket eder; dokununca
/// ya da [AppMotion.showcaseAutoAdvance] sonunda [onDone] çağrılır. Kart
/// koleksiyona eklenmez. [card] null ise (veri yok) hemen geçilir.
class ShowcasePage extends StatefulWidget {
  const ShowcasePage({
    required this.card,
    required this.audio,
    required this.feedback,
    required this.tiltStream,
    required this.shaders,
    required this.onDone,
    super.key,
  });

  /// Vitrinde gösterilen karakter: Rick (2.5D kartı olan tek karakter).
  static const int characterId = 1;

  final GameCardData? card;
  final AudioService audio;
  final UiFeedback feedback;
  final TiltStream tiltStream;
  final ShaderCache shaders;
  final VoidCallback onDone;

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: AppMotion.showcaseDrop,
  );
  Timer? _auto;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    if (widget.card == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _leave());
      return;
    }
    unawaited(widget.audio.playMusic(Music.menuLoop));
    _drop.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        unawaited(widget.audio.play(Sfx.legendaryReveal));
      }
    });
    _auto = Timer(AppMotion.showcaseAutoAdvance, _leave);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.card == null || _drop.isAnimating || _drop.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _drop.value = 1;
    } else {
      unawaited(_drop.forward());
    }
  }

  @override
  void dispose() {
    _auto?.cancel();
    _drop.dispose();
    super.dispose();
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    _auto?.cancel();
    widget.onDone();
  }

  void _tap() {
    widget.feedback.tap();
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: GestureDetector(
        key: const ValueKey('showcase'),
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: ScreenBackground(
          asset: Backgrounds.splash,
          scrim: true,
          child: SafeArea(
            child: card == null
                ? const SizedBox.expand()
                : Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      PortalLoader(
                        active: true,
                        size: AppSizes.showcasePortal,
                        shaders: widget.shaders,
                      ),
                      Expanded(
                        child: Center(
                          child: FallingCard(
                            card: card,
                            drop: _drop,
                            tiltStream: widget.tiltStream,
                            shaders: widget.shaders,
                          ),
                        ),
                      ),
                      Text(card.name, style: AppTypography.headline),
                      const SizedBox(height: AppSpacing.xs),
                      Text(l10n.showcaseHint, style: AppTypography.body),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
