import '../../../l10n/app_localizations.dart';
import '../../game/card_type.dart';
import '../../game/passives.dart';
import '../../game/rarity.dart';

/// Turkish names of game enums (UI text comes only from l10n).
extension CardLabels on AppLocalizations {
  String rarityName(Rarity rarity) => switch (rarity) {
    Rarity.common => rarityCommon,
    Rarity.rare => rarityRare,
    Rarity.epic => rarityEpic,
    Rarity.legendary => rarityLegendary,
  };

  String typeName(CardType type) => switch (type) {
    CardType.human => typeHuman,
    CardType.robot => typeRobot,
    CardType.alien => typeAlien,
    CardType.beast => typeBeast,
    CardType.myth => typeMyth,
    CardType.neutral => typeNeutral,
  };

  /// Null for [Passive.none] (nothing is shown).
  String? passiveName(Passive passive) => switch (passive) {
    Passive.none => null,
    Passive.zombie => passiveZombie,
    Passive.uncertain => passiveUncertain,
  };
}
