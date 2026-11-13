import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../../core/storage/player_state.dart';

/// Ayarlar ekranı verileri (SPEC §2.9): anahtarlar, ses seviyeleri, demo modu (D2),
/// ilerleme sıfırlama.
abstract interface class SettingsRepository {
  PlayerSettings get settings;
  bool get demoUnlocked;
  bool get legendaryArmed;
  int get coins;

  Future<Either<Failure, Unit>> saveSettings(PlayerSettings settings);
  Future<Either<Failure, Unit>> setDemoUnlocked(bool unlocked);

  /// Economy üzerinden +1000 coin, sebep `demo`. Yeni bakiyeyi döndürür.
  Future<Either<Failure, int>> addDemoCoins();

  /// Sonraki portal efsanevi verir (tek seferlik, [GM §7.2]).
  Future<Either<Failure, Unit>> armLegendary();

  /// Oyuncu durumu yeni bir oyuncununkine döner, koleksiyon boşaltılır; senkronlanmış API
  /// verileri ve ayarlar kalır (SPEC §2.9 AC3).
  Future<Either<Failure, Unit>> resetProgress();
}
