import 'package:equatable/equatable.dart';

import 'rarity.dart';

/// Yalnızca karakter id'si ve nadirlikten türetilen sabit kart istatistikleri [GM §4].
/// Aynı id ve nadirlik her zaman aynı istatistikleri verir.
final class CardStats extends Equatable {
  const CardStats({
    required this.hp,
    required this.atk,
    required this.def,
    required this.spd,
  });

  /// `stat = round(base * rarityMult * vary(r(id, k)))`, k: HP 0, ATK 1,
  /// DEF 2, SPD 3.
  factory CardStats.forCharacter(int id, Rarity rarity) =>
      compute(id, rarity, hp: baseHp, atk: baseAtk, def: baseDef, spd: baseSpd);

  /// Açık temel değerlerle [GM §4] formülü (denge simülasyonu,
  /// `tool/battle_sim.dart`). Oyun her zaman [forCharacter] kullanır.
  static CardStats compute(
    int id,
    Rarity rarity, {
    required int hp,
    required int atk,
    required int def,
    required int spd,
  }) {
    int stat(int base, int k) =>
        (base * rarity.statMultiplier * _vary(statRoll(id, k))).round();
    return CardStats(
      hp: stat(hp, _hpIndex),
      atk: stat(atk, _atkIndex),
      def: stat(def, _defIndex),
      spd: stat(spd, _spdIndex),
    );
  }

  final int hp;
  final int atk;
  final int def;
  final int spd;

  static const int baseHp = 100;
  static const int baseAtk = 40;
  static const int baseDef = 12;
  static const int baseSpd = 10;

  static const int _hpIndex = 0;
  static const int _atkIndex = 1;
  static const int _defIndex = 2;
  static const int _spdIndex = 3;

  static const int _knuth = 2654435761;
  static const int _mask32 = 0xFFFFFFFF;
  static const int _idStride = 31;

  /// Temel değer etrafında yayılım: 0.85 ile 1.15 arası (±%15).
  static const double _varyMin = 0.85;
  static const double _varyRange = 0.30;

  static const int _fmixC1 = 0x85EBCA6B;
  static const int _fmixC2 = 0xC2B2AE35;

  /// Knuth çarpımsal hash'i, alt 32 bit. Dart'ın yerel int'leri 64 bittir ve
  /// taşmada başa sarar; bu da alt 32 biti doğru tutar.
  static int hash(int n) => (n * _knuth) & _mask32;

  /// murmur3 `fmix32` sonlandırıcısı. Bu olmadan `hash(id * 31 + k)` `k`'ya göre
  /// doğrusaldır, yani bir kartın ATK, DEF ve SPD çekilişleri HP çekilişinin sabit
  /// bir miktar kaydırılmışı olurdu (tüm istatistik profilleri tek bir eğri üzerinde).
  static int mix(int h) {
    var x = h & _mask32;
    x ^= x >> 16;
    x = (x * _fmixC1) & _mask32;
    x ^= x >> 13;
    x = (x * _fmixC2) & _mask32;
    x ^= x >> 16;
    return x;
  }

  /// [id] karakterinin [k] istatistik indeksi için [0, 1] aralığında deterministik değer.
  static double statRoll(int id, int k) =>
      mix(hash(id * _idStride + k)) / _mask32;

  static double _vary(double x) => _varyMin + _varyRange * x;

  @override
  List<Object> get props => [hp, atk, def, spd];

  @override
  String toString() => 'CardStats(hp: $hp, atk: $atk, def: $def, spd: $spd)';
}
