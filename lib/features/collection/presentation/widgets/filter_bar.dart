import 'package:flutter/material.dart';

import '../../../../app/theme/card_style.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/game/card_type.dart';
import '../../../../core/game/rarity.dart';
import '../../../../core/widgets/game_card/card_labels.dart';
import '../../../../l10n/app_localizations.dart';

/// Kaydırılabilir tek çip satırı (SPEC §5.6): "Hepsi", nadirlikler, tipler.
class FilterBar extends StatelessWidget {
  const FilterBar({
    required this.rarities,
    required this.types,
    required this.onRarity,
    required this.onType,
    required this.onClear,
    super.key,
  });

  final Set<Rarity> rarities;
  final Set<CardType> types;
  final ValueChanged<Rarity> onRarity;
  final ValueChanged<CardType> onType;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chips = <Widget>[
      FilterChip(
        key: const ValueKey('filter-all'),
        label: Text(l10n.collectionAll),
        selected: rarities.isEmpty && types.isEmpty,
        onSelected: (_) => onClear(),
      ),
      for (final r in Rarity.values.reversed)
        FilterChip(
          key: ValueKey('filter-${r.name}'),
          label: Text(l10n.rarityName(r)),
          selected: rarities.contains(r),
          onSelected: (_) => onRarity(r),
        ),
      for (final t in CardType.values)
        FilterChip(
          key: ValueKey('filter-${t.name}'),
          avatar: Icon(CardTypeIcons.of(t), size: AppSizes.iconSmall),
          label: Text(l10n.typeName(t)),
          selected: types.contains(t),
          onSelected: (_) => onType(t),
        ),
    ];
    return SizedBox(
      height: AppSpacing.xxl,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, i) => Center(child: chips[i]),
      ),
    );
  }
}
