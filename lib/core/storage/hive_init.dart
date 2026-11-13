import 'package:hive_ce/hive.dart';

import 'player_state.dart';
import 'stored_models.dart';

/// Kutu isimleri: her toplu veri için bir kutu (mimari kurallar).
abstract final class HiveBoxes {
  static const String characters = 'characters';
  static const String episodes = 'episodes';
  static const String locations = 'locations';
  static const String player = 'player';
  static const String collection = 'collection';
}

/// Adaptörleri kaydeder (işlem başına bir kez) ve Hive'ı [directory] klasörüne yönlendirir.
/// Uygulama `getApplicationSupportDirectory()` verir; testler geçici bir klasör.
void initHive(String directory) {
  Hive.init(directory);
  _register(StoredCharacterAdapter());
  _register(StoredEpisodeAdapter());
  _register(StoredLocationAdapter());
  _register(PlayerSettingsAdapter());
  _register(PlayerStateAdapter());
  _register(OwnedCardAdapter());
}

void _register<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}
