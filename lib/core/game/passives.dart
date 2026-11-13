import 'dart:math';

/// API `status` alanından pasif yetenek [GM §5].
/// Arayüz isimleri: zombie = "Zombi", uncertain = "Belirsiz" (l10n'dan).
enum Passive {
  /// Canlı: pasif yok.
  none,

  /// Ölü: savaşta bir kez, HP 0'a düşünce en yüksek HP'nin %30'u ile dirilir.
  zombie,

  /// Bilinmiyor: her saldırı yarı yarıya ×1.2 veya ×0.8 hasar verir.
  uncertain;

  /// Bir API durum metnini eşler. Dead / unknown dışındaki her şey
  /// Canlı sayılır.
  static Passive fromStatus(String status) =>
      switch (status.trim().toLowerCase()) {
        'dead' => zombie,
        'unknown' => uncertain,
        _ => none,
      };
}

/// Pasiflerin formülleri. Rastgelelik her zaman parametre olarak verilir.
abstract final class Passives {
  static const double zombieReviveFraction = 0.30;
  static const double uncertainChance = 0.5;
  static const double uncertainHigh = 1.2;
  static const double uncertainLow = 0.8;

  /// Zombi kartın geri döndüğü HP: [maxHp]'nin %30'u, yuvarlanmış, en az 1.
  static int zombieReviveHp(int maxHp) =>
      max(1, (maxHp * zombieReviveFraction).round());

  /// [passive] pasifine sahip bir kartın tek saldırısı için hasar çarpanı.
  /// Yalnızca [Passive.uncertain] [random] kullanır; diğerleri ondan çekmeden
  /// 1.0 döndürür, böylece savaşın rastgele sayı dizisini kaydırmazlar.
  static double attackMultiplier(Passive passive, Random random) =>
      switch (passive) {
        Passive.uncertain =>
          random.nextDouble() < uncertainChance ? uncertainHigh : uncertainLow,
        Passive.none || Passive.zombie => 1,
      };
}
