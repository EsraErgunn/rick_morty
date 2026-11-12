import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../../core/storage/player_state.dart';

/// Settings screen data (SPEC §2.9): toggles, volumes, demo mode (D2),
/// progress reset.
abstract interface class SettingsRepository {
  PlayerSettings get settings;
  bool get demoUnlocked;
  bool get legendaryArmed;
  int get coins;

  Future<Either<Failure, Unit>> saveSettings(PlayerSettings settings);
  Future<Either<Failure, Unit>> setDemoUnlocked(bool unlocked);

  /// +1000 coins through Economy, reason `demo`. Returns the new balance.
  Future<Either<Failure, int>> addDemoCoins();

  /// Next portal gives a legendary (one-shot, [GM §7.2]).
  Future<Either<Failure, Unit>> armLegendary();

  /// Player state back to a new player's, collection emptied; synced API
  /// data and settings stay (SPEC §2.9 AC3).
  Future<Either<Failure, Unit>> resetProgress();
}
