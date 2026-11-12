import '../entities/character.dart';
import '../game/rarity.dart';

/// Character ids grouped by rarity, for portal rolls [GM §7]. Built once from
/// the synced characters and held in memory (SPEC §3); rebuilt only after a
/// sync.
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

  /// Sorted ids of [rarity] (empty if none).
  List<int> ids(Rarity rarity) => _ids[rarity]!;

  int get total => _ids.values.fold(0, (sum, list) => sum + list.length);

  Map<Rarity, int> get counts => {
    for (final e in _ids.entries) e.key: e.value.length,
  };
}
