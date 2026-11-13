import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/audio/audio_assets.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/feedback/ui_feedback.dart';
import '../../../../core/widgets/coin_counter.dart';
import '../../../../core/widgets/portal/portal_view.dart';
import '../../../../core/widgets/screen_background.dart';
import '../../../../core/widgets/shader_cache.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/menu_repository.dart';
import '../bloc/menu_bloc.dart';
import '../bloc/menu_state.dart';
import '../widgets/breathing.dart';
import '../widgets/menu_entry.dart';

/// Her menü öğesinin nereye gittiği (router bunları sağlar).
class MenuActions {
  const MenuActions({
    required this.portal,
    required this.collection,
    required this.deck,
    required this.battle,
    required this.album,
    required this.settings,
    this.debugCardLab,
  });

  final VoidCallback portal;
  final VoidCallback collection;
  final VoidCallback deck;
  final VoidCallback battle;
  final VoidCallback album;
  final VoidCallback settings;

  /// Yalnızca debug derlemeler.
  final VoidCallback? debugCardLab;
}

/// Ana menü (SPEC §2.2, §4.2, §5.6): portal görseli, coin'ler, öğeler.
/// Üstünde bir [MenuBloc] bekler.
class MenuPage extends StatefulWidget {
  const MenuPage({
    required this.shaders,
    required this.audio,
    required this.feedback,
    required this.actions,
    this.onShown,
    super.key,
  });

  /// Menü açılınca bir kez çağrılır (arka plan görsellerini ısıtma, T36).
  final VoidCallback? onShown;

  final ShaderCache shaders;
  final AudioService audio;
  final UiFeedback feedback;
  final MenuActions actions;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.audio.playMusic(Music.menuLoop));
    widget.onShown?.call();
  }

  VoidCallback _tap(VoidCallback go) => () {
    widget.feedback.tap();
    go();
  };

  @override
  Widget build(BuildContext context) => BlocConsumer<MenuBloc, MenuState>(
    listenWhen: (a, b) =>
        a.summary != null &&
        b.summary != null &&
        a.summary!.coins != b.summary!.coins,
    // Özet, başka bir ekran menüyü örterken de yenilenir
    // (portal, savaş, ayarlar); coin sesi yalnızca menü görünürken çalar.
    listener: (context, state) {
      if (ModalRoute.isCurrentOf(context) ?? true) widget.feedback.coins();
    },
    builder: (context, state) {
      final s = state.summary;
      if (s == null) return const Scaffold();
      return Scaffold(
        body: ScreenBackground(
          asset: Backgrounds.menu,
          scrim: true,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: _MenuBody(
                summary: s,
                shaders: widget.shaders,
                actions: widget.actions,
                tap: _tap,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _MenuBody extends StatelessWidget {
  const _MenuBody({
    required this.summary,
    required this.shaders,
    required this.actions,
    required this.tap,
  });

  final MenuSummary summary;
  final ShaderCache shaders;
  final MenuActions actions;
  final VoidCallback Function(VoidCallback) tap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = summary;
    final entries = <Widget>[
      MenuEntry(
        label: l10n.collectionTitle,
        value: l10n.menuCount(s.owned, s.totalCharacters),
        onTap: tap(actions.collection),
      ),
      MenuEntry(
        label: l10n.deckTitle,
        value: l10n.menuCount(s.deckSize, MenuSummary.fullDeck),
        onTap: tap(actions.deck),
      ),
      MenuEntry(
        key: const ValueKey('menu-battle'),
        label: l10n.battleTitle,
        hint: l10n.menuDeckHint,
        onTap: s.deckReady ? tap(actions.battle) : null,
      ),
      MenuEntry(
        label: l10n.albumTitle,
        value: l10n.menuCount(s.albumsCompleted, s.albumsTotal),
        onTap: tap(actions.album),
      ),
    ];
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: CoinCounter(coins: s.coins),
          ),
        ),
        Expanded(
          flex: 9,
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: PortalView(shaders: shaders),
            ),
          ),
        ),
        Breathing(
          active: s.collectionEmpty,
          child: FilledButton(
            key: const ValueKey('menu-open-portal'),
            onPressed: tap(actions.portal),
            child: Text(l10n.menuOpenPortal),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final (i, entry) in entries.indexed)
          reduce
              ? entry
              : entry
                    .animate(delay: AppMotion.stagger * i)
                    .fadeIn(duration: AppMotion.normal)
                    .slideX(begin: -0.05, duration: AppMotion.normal),
        const Spacer(),
        Row(
          children: [
            if (actions.debugCardLab case final lab?)
              TextButton(onPressed: lab, child: Text(l10n.cardLabTitle)),
            const Spacer(),
            IconButton(
              tooltip: l10n.menuSettingsTooltip,
              onPressed: tap(actions.settings),
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
      ],
    );
  }
}
