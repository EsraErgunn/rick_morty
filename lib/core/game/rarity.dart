/// Bir karakterin göründüğü bölüm sayısına göre kart nadirliği [GM §2].
///
/// Çerçeve renkleri arayüze aittir ve `app/theme` içinde durur (`AppColors.rarity*`).
enum Rarity {
  common(statMultiplier: 1, holoStrength: 0),
  rare(statMultiplier: 1.15, holoStrength: 0.35),
  epic(statMultiplier: 1.3, holoStrength: 0.65),
  legendary(statMultiplier: 1.5, holoStrength: 1);

  const Rarity({required this.statMultiplier, required this.holoStrength});

  /// Her temel istatistiğe uygulanan çarpan [GM §4].
  final double statMultiplier;

  /// Holo shader'ının `uStrength` değeri (0 = holo katmanı yok).
  final double holoStrength;

  /// Sıradanın üstündeki her kademenin en düşük bölüm sayısı.
  static const int rareMinEpisodes = 2;
  static const int epicMinEpisodes = 5;
  static const int legendaryMinEpisodes = 20;

  /// 1 → sıradan, 2–4 → nadir, 5–19 → epik, 20+ → efsanevi.
  /// 1'in altındaki sayılar API'de olmaz ve sıradan sayılır.
  static Rarity fromEpisodeCount(int episodes) {
    if (episodes >= legendaryMinEpisodes) return legendary;
    if (episodes >= epicMinEpisodes) return epic;
    if (episodes >= rareMinEpisodes) return rare;
    return common;
  }
}
