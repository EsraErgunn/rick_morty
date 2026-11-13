import '../entities/character.dart';
import '../game/rarity.dart';

/// Portal çekilişleri için nadirliğe göre gruplanmış karakter id'leri [GM §7]. Senkronlanmış
/// karakterlerden bir kez kurulur ve bellekte tutulur (SPEC §3); yalnızca bir
/// senkrondan sonra yeniden kurulur.
class RarityPool {
  RarityPool._(this._ids);

  factory RarityPool.fromCharacters(Iterable<Character> characters) {
    final ids = {for (final r in Rarity.values) r: <int>[]};
    for (final c in characters) {
      ids[Rarity.fromEpisodeCount(c.episodeCount)]!.add(c.id);
    }
    return RarityPool._({
      for (final e in ids.entries) e.key: List.unmodifiable(e.value..sort()),
    });
  }

  final Map<Rarity, List<int>> _ids;

  /// [rarity] nadirliğinin sıralı id'leri (yoksa boş).
  List<int> ids(Rarity rarity) => _ids[rarity]!;

  int get total => _ids.values.fold(0, (sum, list) => sum + list.length);

  Map<Rarity, int> get counts => {
    for (final e in _ids.entries) e.key: e.value.length,
  };
}
