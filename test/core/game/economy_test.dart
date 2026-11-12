import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/core/game/economy.dart';
import 'package:portalcards/core/game/rarity.dart';

void main() {
  test('new player starts with 300 coins and a portal costs 100', () {
    expect(EconomyRules.startingCoins, 300);
    expect(EconomyRules.portalCost, 100);
  });

  test('duplicate coins: 20 / 40 / 80 / 200', () {
    expect(Rarity.values.map(Economy.duplicateCoins), [20, 40, 80, 200]);
  });

  test('victory 100 + 25 x tier, defeat 25, draw 50', () {
    expect([0, 1, 4].map(Economy.victoryCoins), [100, 125, 200]);
    expect(EconomyRules.defeatCoins, 25);
    expect(EconomyRules.drawCoins, 50);
  });

  test('album reward min(500, 150 + 10 x members)', () {
    expect(Economy.albumCoins(10), 250);
    expect(Economy.albumCoins(35), 500);
    expect(Economy.albumCoins(60), 500);
  });

  test('spend takes coins and records the reason', () {
    final t = Economy.spend(300, 100, CoinReason.portal)!;
    expect((t.before, t.delta, t.after), (300, -100, 200));
    expect(t.reason, CoinReason.portal);
  });

  test('spend never goes below 0: not enough coins → null', () {
    expect(Economy.spend(99, 100, CoinReason.portal), isNull);
    expect(Economy.canAffordPortal(99), isFalse);
    expect(Economy.canAffordPortal(100), isTrue);
  });

  test('earn adds coins', () {
    final t = Economy.earn(50, EconomyRules.demoBonus, CoinReason.demo);
    expect(t.after, 1050);
    expect(t.toString(), 'coins demo 1000: 50 -> 1050');
  });
}
