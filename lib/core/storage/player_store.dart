import 'package:hive_ce/hive.dart';

import 'hive_init.dart';
import 'player_state.dart';

/// `player` kutusu: sabit bir anahtar altında tek bir [PlayerState]. Açılınca
/// başlangıç durumunu tam olarak bir kez oluşturur (SPEC §2.1 AC6).
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

  /// Her yazımdan sonra tetiklenir (coin, deste, ayarlar, ilerleme). Ekranların
  /// dinlediği tek kaynak; böylece başka bir ekranın altında kalan ekran asla
  /// eski veri göstermez.
  Stream<void> get changes => _box.watch().map((_) {});

  Future<void> save(PlayerState state) => _box.put(_key, state);

  Future<PlayerState> update(PlayerState Function(PlayerState) change) async {
    final next = change(state);
    await save(next);
    return next;
  }

  Future<void> close() => _box.close();
}

/// `collection` kutusu: karakter id'sine göre anahtarlanmış sahip olunan kartlar.
class CollectionStore {
  CollectionStore._(this._box);

  static Future<CollectionStore> open() async =>
      CollectionStore._(await Hive.openBox<OwnedCard>(HiveBoxes.collection));

  final Box<OwnedCard> _box;

  bool owns(int characterId) => _box.containsKey(characterId);

  int copiesOf(int characterId) => _box.get(characterId)?.copies ?? 0;

  Set<int> get ownedIds => _box.keys.cast<int>().toSet();

  Iterable<OwnedCard> get cards => _box.values;

  /// Her yazımdan sonra tetiklenir (kart kazanıldı, kopya eklendi, sıfırlama).
  Stream<void> get changes => _box.watch().map((_) {});

  /// Bir kopya ekler; ilk kopya [at] zamanını kaydeder.
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
