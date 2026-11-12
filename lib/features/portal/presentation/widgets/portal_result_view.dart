import 'package:flutter/material.dart';

import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/game_card/card_back.dart';
import '../../../../core/widgets/game_card/flip_card.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../../../core/widgets/shader_cache.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/portal_repository.dart';
import '../portal_feedback.dart';

/// The portal result: the card back, flipped on tap, then the actions.
/// (The full reveal scene replaces the entrance in plan T30.)
class PortalResultView extends StatefulWidget {
  const PortalResultView({
    required this.result,
    required this.shaders,
    required this.feedback,
    required this.revealed,
    required this.onFinished,
    required this.onOpenAgain,
    required this.onGoToCollection,
    super.key,
  });

  final PortalResult result;
  final ShaderCache shaders;
  final PortalFeedback feedback;
  final bool revealed;
  final VoidCallback onFinished;
  final VoidCallback onOpenAgain;
  final VoidCallback onGoToCollection;

  @override
  State<PortalResultView> createState() => _PortalResultViewState();
}

class _PortalResultViewState extends State<PortalResultView> {
  void _onFlipped(bool showsFront) {
    if (!showsFront) return;
    widget.feedback.flip(widget.result.card.rarity);
    if (widget.result.isDuplicate) widget.feedback.duplicateCoins();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = widget.result;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              width: AppSizes.revealCard,
              child: FlipCard(
                showBack: true,
                // FlipCard reports "back showing"; the front comes up when
                // it reports false.
                onFlipped: (back) => _onFlipped(!back),
                front: GameCard(data: r.card),
                back: const CardBack(),
              ),
            ),
          ),
        ),
        if (widget.revealed) ...[
          Text(
            r.isDuplicate
                ? l10n.portalDuplicate(r.duplicateCoins)
                : l10n.portalNewCard,
            style: AppTypography.title,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onGoToCollection,
                  child: Text(l10n.portalToCollection),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.feedback.button();
                    widget.onOpenAgain();
                  },
                  child: Text(l10n.portalOpenAgain),
                ),
              ),
            ],
          ),
        ] else
          Text(l10n.portalTapToFlip, style: AppTypography.body),
      ],
    );
  }
}
