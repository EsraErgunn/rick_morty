import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/game/featured.dart';

void main() {
  test('five featured characters with their signatures [GM 12]', () {
    expect(Featured.byId, {
      1: Signature.genius,
      2: Signature.awJeez,
      3: Signature.teamSpirit,
      242: Signature.missionComplete,
      265: Signature.pickleArmor,
    });
    expect(Featured.isFeatured(1), isTrue);
    expect(Featured.isFeatured(71), isFalse);
    expect(Featured.signatureOf(71), isNull);
  });

  test('approved signature numbers [GM 12.2]', () {
    expect(SignatureRules.geniusCritChance, 0.20);
    expect(SignatureRules.awJeezHpFraction, 0.30);
    expect(SignatureRules.awJeezMultiplier, 1.5);
    expect(SignatureRules.teamSpiritAtkMultiplier, 1.2);
    expect(SignatureRules.missionCompleteHealFraction, 0.20);
    expect(SignatureRules.pickleArmorMultiplier, 0.5);
  });
}
