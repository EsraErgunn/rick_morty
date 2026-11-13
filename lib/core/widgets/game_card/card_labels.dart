import '../../../l10n/app_localizations.dart';
import '../../game/card_type.dart';
import '../../game/featured.dart';
import '../../game/passives.dart';
import '../../game/rarity.dart';

/// Oyun enum'larının Türkçe isimleri (arayüz metni yalnızca l10n'dan gelir).
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

  /// [Passive.none] için null (hiçbir şey gösterilmez).
  String? passiveName(Passive passive) => switch (passive) {
    Passive.none => null,
    Passive.zombie => passiveZombie,
    Passive.uncertain => passiveUncertain,
  };

  String signatureName(Signature signature) => switch (signature) {
    Signature.genius => signatureGenius,
    Signature.awJeez => signatureAwJeez,
    Signature.teamSpirit => signatureTeamSpirit,
    Signature.missionComplete => signatureMissionComplete,
    Signature.pickleArmor => signaturePickleArmor,
  };
}
