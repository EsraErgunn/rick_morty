/// Every Hive type id in the app, defined once. Never reuse or renumber an
/// id: stored data on players' phones would no longer decode.
abstract final class HiveTypeIds {
  // API data (1-9).
  static const int storedCharacter = 1;
  static const int storedEpisode = 2;
  static const int storedLocation = 3;

  // Game state (10-29).
  static const int playerState = 10;
  static const int playerSettings = 11;
  static const int ownedCard = 12;
}
