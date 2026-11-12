import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../../core/game/economy.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/player_state.dart';
import '../../../core/storage/player_store.dart';
import '../domain/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl({
    required this._player,
    required this._collection,
  });

  final PlayerStore _player;
  final CollectionStore _collection;

  @override
  PlayerSettings get settings => _player.state.settings;
  @override
  bool get demoUnlocked => _player.state.demoUnlocked;
  @override
  bool get legendaryArmed => _player.state.forceNextLegendary;
  @override
  int get coins => _player.state.coins;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() write) async {
    try {
      return right(await write());
    } on Object catch (e, st) {
      AppLogger.error('settings write failed', e, st);
      return left(StorageFailure(e.runtimeType.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveSettings(PlayerSettings settings) =>
      _guard(() async {
        await _player.update((s) => s.copyWith(settings: settings));
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> setDemoUnlocked(bool unlocked) =>
      _guard(() async {
        await _player.update((s) => s.copyWith(demoUnlocked: unlocked));
        return unit;
      });

  @override
  Future<Either<Failure, int>> addDemoCoins() => _guard(() async {
    final t = Economy.earn(coins, EconomyRules.demoBonus, CoinReason.demo);
    await _player.update((s) => s.copyWith(coins: t.after));
    AppLogger.info('$t');
    return t.after;
  });

  @override
  Future<Either<Failure, Unit>> armLegendary() => _guard(() async {
    await _player.update((s) => s.copyWith(forceNextLegendary: true));
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> resetProgress() => _guard(() async {
    final old = _player.state;
    await _collection.clear();
    await _player.save(
      PlayerState(
        settings: old.settings,
        syncProgress: old.syncProgress,
        syncTotals: old.syncTotals,
        syncPages: old.syncPages,
        syncVersion: old.syncVersion,
        syncedAt: old.syncedAt,
      ),
    );
    return unit;
  });
}
