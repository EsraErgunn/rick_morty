import '../entities/character.dart';
import '../game/card_stats.dart';
import '../game/card_type.dart';
import '../game/passives.dart';
import '../game/rarity.dart';
import 'game_card_data.dart';

/// Builds card data from a character using only `core/game` formulas.
abstract final class CardFactory {
  static GameCardData fromCharacter(Character c) {
    final rarity = Rarity.fromEpisodeCount(c.episodeCount);
    return GameCardData(
      id: c.id,
      name: c.name,
      imageUrl: c.imageUrl,
      rarity: rarity,
      type: CardType.fromSpecies(c.species),
      stats: CardStats.forCharacter(c.id, rarity),
      passive: Passive.fromStatus(c.status),
      species: c.species,
      status: c.status,
      originName: c.originName,
      locationName: c.locationName,
      episodeCount: c.episodeCount,
    );
  }
}
