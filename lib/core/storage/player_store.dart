import 'package:hive_ce/hive.dart';

import 'hive_init.dart';
import 'player_state.dart';

/// The `player` box: one [PlayerState] under a fixed key. Opening it creates
/// the starting state exactly once (SPEC §2.1 AC6).
class PlayerStore {
  PlayerStore._(this._box);

  static const String _key = 'state';

  static Future<PlayerStore> open() async {
    final box = await Hive.openBox<PlayerState>(HiveBoxes.player);
    if (!box.containsKey(_key)) await box.put(_key, const PlayerState());
    return PlayerStore._(box);
  }

  final Box<PlayerState> _box;

  PlayerState get state => _box.get(_key)!;

  /// Fires after every write (coins, deck, settings, progress). The single
  /// source screens listen to, so a screen kept under another one never
  /// shows stale data.
  Stream<void> get changes => _box.watch().map((_) {});

  Future<void> save(PlayerState state) => _box.put(_key, state);

  Future<PlayerState> update(PlayerState Function(PlayerState) change) async {
    final next = change(state);
    await save(next);
    return next;
  }

  Future<void> close() => _box.close();
}

/// The `collection` box: owned cards keyed by character id.
class CollectionStore {
  CollectionStore._(this._box);

  static Future<CollectionStore> open() async =>
      CollectionStore._(await Hive.openBox<OwnedCard>(HiveBoxes.collection));

  final Box<OwnedCard> _box;

  bool owns(int characterId) => _box.containsKey(characterId);

  int copiesOf(int characterId) => _box.get(characterId)?.copies ?? 0;

  Set<int> get ownedIds => _box.keys.cast<int>().toSet();

  Iterable<OwnedCard> get cards => _box.values;

  /// Fires after every write (a card won, a copy added, a reset).
  Stream<void> get changes => _box.watch().map((_) {});

  /// Adds one copy; the first copy records [at].
  Future<OwnedCard> addCopy(int characterId, DateTime at) async {
    final current = _box.get(characterId);
    final next = OwnedCard(
      characterId: characterId,
      copies: (current?.copies ?? 0) + 1,
      firstObtainedAt: current?.firstObtainedAt ?? at,
    );
    await _box.put(characterId, next);
    return next;
  }

  Future<void> clear() => _box.clear();

  Future<void> close() => _box.close();
}
