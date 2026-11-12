/// Card rarity from the number of episodes a character appears in [GM §2].
///
/// Frame colors are UI and live in `app/theme` (`AppColors.rarity*`).
enum Rarity {
  common(statMultiplier: 1, holoStrength: 0),
  rare(statMultiplier: 1.15, holoStrength: 0.35),
  epic(statMultiplier: 1.3, holoStrength: 0.65),
  legendary(statMultiplier: 1.5, holoStrength: 1);

  const Rarity({required this.statMultiplier, required this.holoStrength});

  /// Multiplier applied to every base stat [GM §4].
  final double statMultiplier;

  /// `uStrength` of the holo shader (0 = no holo layer).
  final double holoStrength;

  /// Lowest episode count of each tier above common.
  static const int rareMinEpisodes = 2;
  static const int epicMinEpisodes = 5;
  static const int legendaryMinEpisodes = 20;

  /// 1 → common, 2–4 → rare, 5–19 → epic, 20+ → legendary.
  /// Counts below 1 do not occur in the API and are treated as common.
  static Rarity fromEpisodeCount(int episodes) {
    if (episodes >= legendaryMinEpisodes) return legendary;
    if (episodes >= epicMinEpisodes) return epic;
    if (episodes >= rareMinEpisodes) return rare;
    return common;
  }
}
