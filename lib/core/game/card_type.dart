/// API `species` alanından kart tipi [GM §3].
///
/// Ana üçgen (ok = şuna karşı süper etkili):
/// İnsan → Robot → Uzaylı → İnsan. Canavar ve Efsanevi yaratığın özel özellikleri vardır
/// (savaş motoru uygular); Nötr'ün yoktur.
enum CardType {
  human,
  robot,
  alien,
  beast,
  myth,
  neutral;

  /// Bir API tür metnini eşler. Bilinmeyen veya yeni türler [neutral] olur.
  static CardType fromSpecies(String species) =>
      switch (species.trim().toLowerCase()) {
        'human' || 'humanoid' => human,
        'robot' => robot,
        'alien' => alien,
        'animal' => beast,
        'mythological creature' => myth,
        _ => neutral,
      };

  /// Bu tipin süper etkili olduğu tip; üçgenin dışındaysa
  /// null.
  CardType? get strongAgainst => switch (this) {
    human => robot,
    robot => alien,
    alien => human,
    beast || myth || neutral => null,
  };
}

/// Tipler yüzünden bir saldırının ne kadar etkili olduğu; arayüz ilk ikisi için
/// bir yazı gösterir ("SÜPER ETKİLİ!", "Pek etkili değil…").
enum Effectiveness {
  superEffective(1.5),
  notVeryEffective(0.75),
  normal(1);

  const Effectiveness(this.multiplier);

  final double multiplier;

  static Effectiveness of(CardType attacker, CardType defender) {
    if (attacker.strongAgainst == defender) return superEffective;
    if (defender.strongAgainst == attacker) return notVeryEffective;
    return normal;
  }
}

/// [attacker] [defender]'a vurduğunda hasar çarpanı: ×1.5, ×0.75 veya ×1.
double typeMultiplier(CardType attacker, CardType defender) =>
    Effectiveness.of(attacker, defender).multiplier;
