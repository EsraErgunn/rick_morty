import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../../core/game/economy.dart';
import '../../../core/game/god_mode.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/api_data_store.dart';
import '../../../core/storage/god_mode_store.dart';
import '../../../core/storage/player_state.dart';
import '../../../core/storage/player_store.dart';
import '../domain/settings_repository.dart';

/// [SettingsRepository]'nin Hive depolarıyla çalışan uygulaması.
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl({
    required this._player,
    required this._collection,
    required this._godBackup,
    required this._apiData,
    required this._clock,
  });

  final PlayerStore _player;
  final CollectionStore _collection;
  final GodModeStore _godBackup;
  final ApiDataStore _apiData;
  final DateTime Function() _clock;

  @override
  PlayerSettings get settings => _player.state.settings;
  @override
  bool get demoUnlocked => _player.state.demoUnlocked;
  @override
  bool get legendaryArmed => _player.state.forceNextLegendary;
  @override
  int get coins => _player.state.coins;
  @override
  bool get godMode => _player.state.godMode;

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
  Future<Either<Failure, Unit>> setGodMode(bool on) => _guard(() async {
    final now = _player.state;
    if (on == now.godMode) return unit;
    if (on) {
      await _godBackup.save(now, _collection.cards);
      await _collection.addMissing([
        for (final c in _apiData.characters) c.id,
      ], _clock());
      final t = Economy.earn(
        now.coins,
        GodModeRules.coins - now.coins,
        CoinReason.demo,
      );
      AppLogger.info('god mode on, $t');
      await _player.update(
        (s) =>
            s.copyWith(godMode: true, coins: t.after, wins: GodModeRules.wins),
      );
    } else {
      final real = _godBackup.player ?? now;
      await _collection.clear();
      await _collection.putAll(_godBackup.cards);
      await _player.save(
        real.copyWith(
          settings: now.settings,
          demoUnlocked: now.demoUnlocked,
          onboardingSeen: now.onboardingSeen,
          godMode: false,
        ),
      );
      await _godBackup.clear();
      AppLogger.info('god mode off, real progress restored');
    }
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> resetProgress() => _guard(() async {
    final old = _player.state;
    await _godBackup.clear();
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
