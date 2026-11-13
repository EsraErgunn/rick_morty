import 'opponents.dart';

/// God mode değerleri [GM §7.2]: gizli demo panelinden açılan bir sunum
/// modu. Oyun kurallarını değiştirmez; yalnızca oyuncunun verisini doldurur.
abstract final class GodModeRules {
  /// God mode'da coin her zaman bu değere tamamlanır.
  static const int coins = 999999;

  /// En yüksek kademeye ulaşan galibiyet sayısı.
  static const int wins = Opponents.maxTier * Opponents.winsPerTier;
}
