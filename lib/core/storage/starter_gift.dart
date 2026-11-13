import '../game/portal_roll.dart';
import 'player_store.dart';

/// Applies the starter Rick rule [GM §7.1] to players from before it: if
/// portals were already opened and Rick is not owned, he is added once.
/// New players get him from their first portal instead. Runs at startup;
/// the check happens only once per save.
abstract final class StarterGift {
  static Future<bool> apply({
    required PlayerStore player,
    required CollectionStore collection,
    required DateTime now,
  }) async {
    final state = player.state;
    if (state.starterChecked) return false;
    final gift =
        state.portalsOpened > 0 &&
        !collection.owns(PortalRoll.starterCharacterId);
    if (gift) await collection.addCopy(PortalRoll.starterCharacterId, now);
    await player.update((s) => s.copyWith(starterChecked: true));
    return gift;
  }
}
