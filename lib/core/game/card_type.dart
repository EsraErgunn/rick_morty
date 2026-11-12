/// Card type from the API `species` [GM §3].
///
/// Core triangle (arrow = super effective against):
/// Human → Robot → Alien → Human. Beast and Myth have special traits
/// (applied by the battle engine); Neutral has none.
enum CardType {
  human,
  robot,
  alien,
  beast,
  myth,
  neutral;

  /// Maps an API species string. Unknown or new species become [neutral].
  static CardType fromSpecies(String species) =>
      switch (species.trim().toLowerCase()) {
        'human' || 'humanoid' => human,
        'robot' => robot,
        'alien' => alien,
        'animal' => beast,
        'mythological creature' => myth,
        _ => neutral,
      };

  /// The type this one is super effective against, or null outside the
  /// triangle.
  CardType? get strongAgainst => switch (this) {
    human => robot,
    robot => alien,
    alien => human,
    beast || myth || neutral => null,
  };
}

/// How well an attack lands because of types; the UI shows a text for the
/// first two ("SÜPER ETKİLİ!", "Pek etkili değil…").
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

/// Damage multiplier for [attacker] hitting [defender]: ×1.5, ×0.75 or ×1.
double typeMultiplier(CardType attacker, CardType defender) =>
    Effectiveness.of(attacker, defender).multiplier;
