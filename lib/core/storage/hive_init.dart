import 'package:hive_ce/hive.dart';

import 'stored_models.dart';

/// Box names: one box per aggregate (architecture rules).
abstract final class HiveBoxes {
  static const String characters = 'characters';
  static const String episodes = 'episodes';
  static const String locations = 'locations';
  static const String player = 'player';
  static const String collection = 'collection';
}

/// Registers adapters (once per process) and points Hive at [directory].
/// The app passes `getApplicationSupportDirectory()`; tests a temp dir.
void initHive(String directory) {
  Hive.init(directory);
  _register(StoredCharacterAdapter());
  _register(StoredEpisodeAdapter());
  _register(StoredLocationAdapter());
}

void _register<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}
