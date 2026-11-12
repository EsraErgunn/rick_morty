import 'package:equatable/equatable.dart';

import 'rarity.dart';

/// Fixed card stats, derived only from the character id and rarity [GM §4].
/// The same id and rarity always give the same stats.
final class CardStats extends Equatable {
  const CardStats({
    required this.hp,
    required this.atk,
    required this.def,
    required this.spd,
  });

  /// `stat = round(base * rarityMult * vary(r(id, k)))`, k: HP 0, ATK 1,
  /// DEF 2, SPD 3.
  factory CardStats.forCharacter(int id, Rarity rarity) {
    int stat(int base, int k) =>
        (base * rarity.statMultiplier * _vary(statRoll(id, k))).round();
    return CardStats(
      hp: stat(baseHp, _hpIndex),
      atk: stat(baseAtk, _atkIndex),
      def: stat(baseDef, _defIndex),
      spd: stat(baseSpd, _spdIndex),
    );
  }

  final int hp;
  final int atk;
  final int def;
  final int spd;

  static const int baseHp = 100;
  static const int baseAtk = 20;
  static const int baseDef = 12;
  static const int baseSpd = 10;

  static const int _hpIndex = 0;
  static const int _atkIndex = 1;
  static const int _defIndex = 2;
  static const int _spdIndex = 3;

  static const int _knuth = 2654435761;
  static const int _mask32 = 0xFFFFFFFF;
  static const int _idStride = 31;

  /// Spread around the base: 0.85 to 1.15 (±15%).
  static const double _varyMin = 0.85;
  static const double _varyRange = 0.30;

  /// Knuth multiplicative hash, low 32 bits. Dart native ints are 64-bit and
  /// wrap on overflow, which keeps the low 32 bits exact.
  static int hash(int n) => (n * _knuth) & _mask32;

  /// Deterministic value in [0, 1] for stat index [k] of character [id].
  static double statRoll(int id, int k) => hash(id * _idStride + k) / _mask32;

  static double _vary(double x) => _varyMin + _varyRange * x;

  @override
  List<Object> get props => [hp, atk, def, spd];

  @override
  String toString() => 'CardStats(hp: $hp, atk: $atk, def: $def, spd: $spd)';
}
