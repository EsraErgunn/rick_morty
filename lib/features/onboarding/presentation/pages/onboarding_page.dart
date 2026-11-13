import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/audio/audio_assets.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/feedback/ui_feedback.dart';
import '../../../../core/sensors/tilt_stream.dart';
import '../../../../core/widgets/screen_background.dart';
import '../../../../core/widgets/shader_cache.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../widgets/battle_slide_art.dart';
import '../widgets/cards_slide_art.dart';
import '../widgets/deck_slide_art.dart';
import '../widgets/onboarding_slide.dart';
import '../widgets/portal_slide_art.dart';

/// First-launch intro: four swipeable pages, "Geç" top right, dots and
/// "İleri" / "Başla" at the bottom, `menu_loop` playing. Finishing (or
/// skipping) marks it seen and calls [onDone].
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    required this.audio,
    required this.feedback,
    required this.tiltStream,
    required this.shaders,
    required this.onDone,
    super.key,
  });

  final AudioService audio;
  final UiFeedback feedback;
  final TiltStream tiltStream;
  final ShaderCache shaders;
  final VoidCallback onDone;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pages = PageController();

  @override
  void initState() {
    super.initState();
    unawaited(widget.audio.playMusic(Music.menuLoop));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    widget.feedback.tap();
    context.read<OnboardingBloc>().add(const OnboardingFinished());
  }

  void _next() {
    widget.feedback.tap();
    final reduced = MediaQuery.disableAnimationsOf(context);
    final next = context.read<OnboardingBloc>().state.page + 1;
    if (reduced) {
      _pages.jumpToPage(next);
    } else {
      unawaited(
        _pages.nextPage(duration: AppMotion.normal, curve: AppMotion.move),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (a, b) =>
          a.status != b.status &&
          (b.status == OnboardingStatus.success ||
              b.status == OnboardingStatus.failure),
      listener: (context, state) => widget.onDone(),
      builder: (context, state) {
        final slides = [
          OnboardingSlide(
            art: PortalSlideArt(shaders: widget.shaders),
            title: l10n.onboardingPortalTitle,
            body: l10n.onboardingPortalBody,
          ),
          OnboardingSlide(
            art: CardsSlideArt(
              cards: state.cards,
              tiltStream: widget.tiltStream,
              shaders: widget.shaders,
            ),
            title: l10n.onboardingCardsTitle,
            body: l10n.onboardingCardsBody,
          ),
          OnboardingSlide(
            art: const DeckSlideArt(),
            title: l10n.onboardingDeckTitle,
            body: l10n.onboardingDeckBody,
          ),
          OnboardingSlide(
            art: BattleSlideArt(cards: state.cards),
            title: l10n.onboardingBattleTitle,
            body: l10n.onboardingBattleBody,
          ),
        ];
        return Scaffold(
          body: ScreenBackground(
            asset: Backgrounds.menu,
            scrim: true,
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: TextButton(
                        key: const ValueKey('onboarding-skip'),
                        onPressed: _finish,
                        child: Text(l10n.onboardingSkip),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (i) => context.read<OnboardingBloc>().add(
                        OnboardingPageChanged(i),
                      ),
                      children: slides,
                    ),
                  ),
                  PageDots(
                    count: OnboardingState.pageCount,
                    current: state.page,
                    label: l10n.onboardingPageLabel(
                      state.page + 1,
                      OnboardingState.pageCount,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('onboarding-next'),
                        onPressed: state.isLast ? _finish : _next,
                        child: Text(
                          state.isLast
                              ? l10n.onboardingStart
                              : l10n.onboardingNext,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
