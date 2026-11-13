import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/card_style.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/feedback/ui_feedback.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/floating.dart';
import '../../../../core/widgets/game_card/game_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/album_bloc.dart';
import '../bloc/album_state.dart';

/// One episode page [GM §9]: owned characters with art, missing ones as
/// silhouettes. Expects an [AlbumPageBloc] above it.
class AlbumEpisodePage extends StatelessWidget {
  const AlbumEpisodePage({required this.feedback, super.key});

  final UiFeedback feedback;

  static const int _columns = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AlbumPageBloc, AlbumPageState>(
      builder: (context, state) {
        final e = state.episode;
        return Scaffold(
          appBar: AppBar(
            leading: AppBackButton(onFeedback: feedback.tap),
            title: Text(
              e == null
                  ? l10n.albumTitle
                  : l10n.albumEpisodeTitle(e.code, e.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: e == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.sm,
                        AppSpacing.gutter,
                        0,
                      ),
                      child: Text(
                        e.complete
                            ? l10n.albumDone
                            : l10n.menuCount(e.owned, e.total),
                        style: AppTypography.label.copyWith(
                          color: e.complete
                              ? AppColors.portal
                              : AppColors.paperMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.gutter),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _columns,
                              mainAxisSpacing: AppSpacing.sm,
                              crossAxisSpacing: AppSpacing.sm,
                              childAspectRatio: CardMetrics.aspect,
                            ),
                        itemCount: state.members.length,
                        itemBuilder: (context, i) {
                          final m = state.members[i];
                          final card = RepaintBoundary(
                            child: GameCard(data: m.card),
                          );
                          return Floating(
                            key: ValueKey('member-${m.card.id}'),
                            phase: Floating.phaseFor(i),
                            child: m.owned ? card : _Silhouette(card: card),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// A missing character: the card as a dark shape with a question mark.
class _Silhouette extends StatelessWidget {
  const _Silhouette({required this.card});

  final Widget card;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ColorFiltered(
        colorFilter: const ColorFilter.mode(
          AppColors.voidRaised,
          BlendMode.srcATop,
        ),
        child: card,
      ),
      Center(
        child: Text(
          '?',
          style: AppTypography.display.copyWith(color: AppColors.paperMuted),
        ),
      ),
    ],
  );
}
