/// Uygulamadaki her Hive tip id'si, bir kez tanımlı. Bir id'yi asla yeniden kullanma
/// veya numarasını değiştirme: oyuncuların telefonlarındaki kayıtlı veri artık çözülemez.
abstract final class HiveTypeIds {
  // API verileri (1-9).
  static const int storedCharacter = 1;
  static const int storedEpisode = 2;
  static const int storedLocation = 3;

  // Oyun durumu (10-29).
  static const int playerState = 10;
  static const int playerSettings = 11;
  static const int ownedCard = 12;
}
