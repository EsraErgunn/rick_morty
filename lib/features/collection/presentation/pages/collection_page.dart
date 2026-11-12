import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/motion.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/feedback/ui_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/collection_bloc.dart';
import '../bloc/collection_event.dart';
import '../bloc/collection_state.dart';
import '../widgets/collection_grid.dart';
import '../widgets/filter_bar.dart';

/// Collection (SPEC §2.4, §4.4, §5.6). Expects a [CollectionBloc] above it.
class CollectionPage extends StatelessWidget {
  const CollectionPage({
    required this.feedback,
    required this.onOpenCard,
    required this.onOpenPortal,
    super.key,
  });

  final UiFeedback feedback;
  final ValueChanged<int> onOpenCard;
  final VoidCallback onOpenPortal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<CollectionBloc>();
    void filter(CollectionEvent e) {
      feedback.tap();
      bloc.add(e);
    }

    return BlocBuilder<CollectionBloc, CollectionState>(
      builder: (context, state) {
        final visible = state.visible;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.collectionTitle),
            actions: [
              Center(
                child: Text(
                  l10n.menuCount(state.entries.length, state.total),
                  style: AppTypography.stat,
                ),
              ),
              PopupMenuButton<CollectionSort>(
                tooltip: l10n.collectionSortTooltip,
                icon: const Icon(Icons.sort),
                onSelected: (s) => filter(CollectionSortChanged(s)),
                itemBuilder: (_) => [
                  for (final (s, label) in [
                    (CollectionSort.rarity, l10n.collectionSortRarity),
                    (CollectionSort.name, l10n.collectionSortName),
                    (CollectionSort.newest, l10n.collectionSortNewest),
                  ])
                    CheckedPopupMenuItem(
                      value: s,
                      checked: state.sort == s,
                      child: Text(label),
                    ),
                ],
              ),
            ],
          ),
          body: state.entries.isEmpty
              ? _Empty(
                  message: l10n.collectionEmpty,
                  action: l10n.menuOpenPortal,
                  onAction: () {
                    feedback.tap();
                    onOpenPortal();
                  },
                )
              : Column(
                  children: [
                    FilterBar(
                      rarities: state.rarities,
                      types: state.types,
                      onRarity: (r) => filter(CollectionRarityToggled(r)),
                      onType: (t) => filter(CollectionTypeToggled(t)),
                      onClear: () => filter(const CollectionFiltersCleared()),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: AppMotion.normal,
                        switchInCurve: AppMotion.move,
                        child: visible.isEmpty
                            ? _Empty(message: l10n.collectionFilteredEmpty)
                            : CollectionGrid(
                                key: ValueKey(
                                  '${state.rarities}${state.types}${state.sort}',
                                ),
                                entries: visible,
                                onOpen: (id) {
                                  feedback.cardFlip();
                                  onOpenCard(id);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, this.action, this.onAction});

  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center, style: AppTypography.body),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}
