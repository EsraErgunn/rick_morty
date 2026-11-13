import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/feedback/ui_feedback.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/album_bloc.dart';
import '../bloc/album_state.dart';
import '../widgets/episode_tile.dart';

/// Episode album [GM §9]: seasons, each episode with `owned/total`.
/// Announces paid page rewards. Expects an [AlbumBloc] above it.
class AlbumPage extends StatelessWidget {
  const AlbumPage({required this.feedback, required this.onOpen, super.key});

  final UiFeedback feedback;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<AlbumBloc, AlbumState>(
      listenWhen: (a, b) => a.rewardTick != b.rewardTick,
      listener: (context, state) {
        feedback.coins();
        final messenger = ScaffoldMessenger.of(context);
        for (final r in state.rewards) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.albumReward(r.code, r.coins))),
          );
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          leading: AppBackButton(onFeedback: feedback.tap),
          title: Text(l10n.albumTitle),
        ),
        body: switch (state) {
          AlbumState(status: AlbumStatus.initial) => const SizedBox.shrink(),
          AlbumState(episodes: []) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Text(
                l10n.albumEmpty,
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
            ),
          ),
          _ => ListView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              Text(
                l10n.albumCompleted(state.completed, state.episodes.length),
                style: AppTypography.label.copyWith(
                  color: AppColors.paperMuted,
                ),
              ),
              for (final MapEntry(key: season, value: list)
                  in state.seasons.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.lg,
                    bottom: AppSpacing.xs,
                  ),
                  child: Text(
                    l10n.albumSeason(season),
                    style: AppTypography.title,
                  ),
                ),
                for (final e in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: EpisodeTile(
                      episode: e,
                      onTap: () {
                        feedback.tap();
                        onOpen(e.id);
                      },
                    ),
                  ),
              ],
            ],
          ),
        },
      ),
    );
  }
}
