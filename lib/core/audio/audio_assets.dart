/// Ses efektleri (`assets/audio/sfx/`, `tools/audio` tarafından üretildi).
enum Sfx {
  portalCharge('portal_charge'),
  portalOpen('portal_open'),
  cardFlip('card_flip'),
  rareReveal('rare_reveal'),
  legendaryReveal('legendary_reveal'),
  hit('hit'),
  critHit('crit_hit'),
  superEffective('super_effective'),
  faint('faint'),
  victory('victory'),
  defeat('defeat'),
  buttonTap('button_tap'),
  coin('coin'),
  geniusCrit('genius_crit'),
  meeseeksPoof('meeseeks_poof');

  const Sfx(this.file);

  final String file;

  /// audioplayers'ın `AssetSource`'u için yol (`assets/` önekini kendisi ekler).
  String get asset => 'audio/sfx/$file.wav';
}

/// Müzik (`assets/audio/music/`). Döngüler tekrar eder; sting bir kez çalar.
enum Music {
  menuLoop('menu_loop', loops: true),
  battleLoop('battle_loop', loops: true),
  legendarySting('legendary_sting', loops: false);

  const Music(this.file, {required this.loops});

  final String file;
  final bool loops;

  String get asset => 'audio/music/$file.wav';
}
