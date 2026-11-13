/// Öne çıkan karakterler [GM §12]: herkesle aynı nadirlik, tip, istatistik ve portal
/// şansı; bunlara bir çerçeve, bir özel yetenek (savaş,
/// 3. hafta) ve bir giriş sinematiği eklenir.
enum Signature {
  /// Rick: kritik şansı %10 yerine %20; kritikte "DAHİ!" gösterilir.
  genius,

  /// Morty: HP ilk kez ≤ %30 olunca sonraki saldırı ×1.5 (bir kez).
  awJeez,

  /// Summer: bir takım arkadaşı bayılınca geri kalan sürede ATK ×1.2 (bir kez).
  teamSpirit,

  /// Mr. Meeseeks: rakibi bayıltınca en yüksek HP'nin %20'si kadar iyileşir (bir kez).
  missionComplete,

  /// Pickle Rick: aldığı ilk saldırı ×0.5 hasar verir.
  pickleArmor,
}

/// Onaylanan sayılar [GM §12.2] (proje sahibi, 2026-11-12). 3. haftada savaş
/// motoru tarafından kullanılır.
abstract final class SignatureRules {
  static const double geniusCritChance = 0.20;
  static const double awJeezHpFraction = 0.30;
  static const double awJeezMultiplier = 1.5;
  static const double teamSpiritAtkMultiplier = 1.2;
  static const double missionCompleteHealFraction = 0.20;
  static const double pickleArmorMultiplier = 0.5;
}

/// Öne çıkan karakterlerin listesi ve sorgulama yardımcıları [GM §12].
abstract final class Featured {
  /// API id → özel yetenek (MVP: 5 karakter).
  static const Map<int, Signature> byId = {
    1: Signature.genius,
    2: Signature.awJeez,
    3: Signature.teamSpirit,
    242: Signature.missionComplete,
    265: Signature.pickleArmor,
  };

  static bool isFeatured(int id) => byId.containsKey(id);

  static Signature? signatureOf(int id) => byId[id];
}
