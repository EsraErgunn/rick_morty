/// Featured characters [GM §12]: same rarity, type, stats and portal
/// chances as everyone; they add a frame, a signature ability (battle,
/// Week 3) and an entrance cinematic.
enum Signature {
  /// Rick: crit chance 20 % instead of 10 %; crit shows "DAHİ!".
  genius,

  /// Morty: first time HP ≤ 30 %, next attack ×1.5 (once).
  awJeez,

  /// Summer: when an ally faints, ATK ×1.2 for the rest (once).
  teamSpirit,

  /// Mr. Meeseeks: on a KO, heal 20 % of max HP (once).
  missionComplete,

  /// Pickle Rick: the first attack received deals ×0.5.
  pickleArmor,
}

/// Approved numbers [GM §12.2] (owner, 2026-11-12). Used by the battle
/// engine in Week 3.
abstract final class SignatureRules {
  static const double geniusCritChance = 0.20;
  static const double awJeezHpFraction = 0.30;
  static const double awJeezMultiplier = 1.5;
  static const double teamSpiritAtkMultiplier = 1.2;
  static const double missionCompleteHealFraction = 0.20;
  static const double pickleArmorMultiplier = 0.5;
}

abstract final class Featured {
  /// API id → signature (MVP: 5 characters).
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
