import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:portalcards/core/game/economy.dart';
import 'package:portalcards/core/storage/player_state.dart';
import 'package:portalcards/core/storage/player_store.dart';

import 'hive_test_helper.dart';

Future<PlayerStore> _reopen(PlayerStore store) async {
  await store.close();
  await Hive.close();
  return PlayerStore.open();
}

void main() {
  useTempHive();

  group('PlayerStore', () {
    test('first open creates the starting state (SPEC 2.1 AC6)', () async {
      final store = await PlayerStore.open();
      final s = store.state;

      expect(s.coins, 300);
      expect(s.coins, EconomyRules.startingCoins);
      expect(s.settings, const PlayerSettings());
      expect(s.settings.soundEnabled, isTrue);
      expect(s.settings.musicEnabled, isTrue);
      expect(s.settings.hapticsEnabled, isTrue);
      expect(s.deck, isEmpty);
      expect(s.wins, 0);
      expect(s.portalsOpened, 0);
      expect(s.shakeHintSeen, isFalse);
      expect(s.completedAlbums, isEmpty);
      expect(s.demoUnlocked, isFalse);
      expect(s.forceNextLegendary, isFalse);
      expect(s.syncProgress, isEmpty);
      expect(s.syncTotals, isEmpty);
      expect(s.syncVersion, isNull);
      expect(s.syncedAt, isNull);
      expect(s.isSynced, isFalse);
    });

    test('a second open does not reset anything', () async {
      var store = await PlayerStore.open();
      final changed = PlayerState(
        coins: 120,
        settings: const PlayerSettings(musicEnabled: false, sfxVolume: 0.4),
        deck: const [1, 2, 71],
        wins: 5,
        portalsOpened: 4,
        shakeHintSeen: true,
        completedAlbums: const [1],
        demoUnlocked: true,
        forceNextLegendary: true,
        syncProgress: const {'character': 42, 'episode': 3, 'location': 7},
        syncTotals: const {'character': 826, 'episode': 51, 'location': 126},
        syncVersion: 1,
        syncedAt: DateTime.utc(2026, 11, 12, 10, 30),
      );
      await store.save(changed);

      store = await _reopen(store);

      expect(store.state, changed);
    });

    test('update applies a change and persists it', () async {
      var store = await PlayerStore.open();
      await store.update((s) => s.copyWith(portalsOpened: s.portalsOpened + 1));

      store = await _reopen(store);

      expect(store.state.portalsOpened, 1);
      expect(store.state.coins, 300);
    });
  });

  group('CollectionStore', () {
    test('starts empty', () async {
      final store = await CollectionStore.open();
      expect(store.ownedIds, isEmpty);
      expect(store.owns(1), isFalse);
      expect(store.copiesOf(1), 0);
    });

    test('counts copies and keeps the first obtained time', () async {
      var store = await CollectionStore.open();
      final first = DateTime.utc(2026, 11, 12);
      await store.addCopy(1, first);
      await store.addCopy(1, DateTime.utc(2026, 11, 13));
      await store.addCopy(71, first);

      await store.close();
      await Hive.close();
      store = await CollectionStore.open();

      expect(store.ownedIds, {1, 71});
      expect(store.copiesOf(1), 2);
      expect(
        store.cards.firstWhere((c) => c.characterId == 1).firstObtainedAt,
        first,
      );
    });
  });
}
