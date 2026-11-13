import 'package:hive_ce/hive.dart';

import 'hive_init.dart';
import 'player_state.dart';

/// God mode yedeği: god mode açılmadan önceki gerçek oyuncu durumu ve
/// koleksiyon burada saklanır, kapatınca geri yüklenir [GM §7.2].
class GodModeStore {
  GodModeStore._(this._player, this._cards);

  static const String _key = 'state';

  static Future<GodModeStore> open() async => GodModeStore._(
    await Hive.openBox<PlayerState>(HiveBoxes.godBackupPlayer),
    await Hive.openBox<OwnedCard>(HiveBoxes.godBackupCollection),
  );

  final Box<PlayerState> _player;
  final Box<OwnedCard> _cards;

  /// Bir yedek kayıtlıysa true.
  bool get hasBackup => _player.containsKey(_key);

  /// Gerçek durumu yedekler (önceki yedeğin üstüne yazar).
  Future<void> save(PlayerState state, Iterable<OwnedCard> cards) async {
    await _cards.clear();
    await _cards.putAll({for (final c in cards) c.characterId: c});
    await _player.put(_key, state);
  }

  /// Yedeklenen oyuncu durumu (yoksa null).
  PlayerState? get player => _player.get(_key);

  /// Yedeklenen kartlar.
  List<OwnedCard> get cards => _cards.values.toList();

  /// Yedeği siler.
  Future<void> clear() async {
    await _cards.clear();
    await _player.clear();
  }
}
