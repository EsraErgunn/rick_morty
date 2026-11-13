import 'package:equatable/equatable.dart';

import '../../../core/cards/game_card_data.dart';

/// One episode page of the album [GM §9]: `owned / total` characters.
final class AlbumEpisode extends Equatable {
  const AlbumEpisode({
    required this.id,
    required this.code,
    required this.name,
    required this.owned,
    required this.total,
  });

  final int id;

  /// `S01E01`.
  final String code;
  final String name;
  final int owned;
  final int total;

  /// Season number from the code (`S03E07` → 3); 0 if the code is odd.
  int get season =>
      int.tryParse(code.length >= 3 ? code.substring(1, 3) : '') ?? 0;

  bool get complete => total > 0 && owned >= total;

  @override
  List<Object?> get props => [id, code, name, owned, total];
}

/// One character on an episode page: art when owned, a silhouette if not.
final class AlbumMember extends Equatable {
  const AlbumMember({required this.card, required this.owned});

  final GameCardData card;
  final bool owned;

  @override
  List<Object?> get props => [card, owned];
}

/// An album reward that was just paid ([GM §8]: once per episode).
final class AlbumReward extends Equatable {
  const AlbumReward({required this.code, required this.coins});

  final String code;
  final int coins;

  @override
  List<Object?> get props => [code, coins];
}

abstract interface class AlbumRepository {
  /// Every episode, sorted by code (`S01E01` first).
  List<AlbumEpisode> episodes();

  AlbumEpisode? episode(int id);

  /// The episode's characters in API order.
  List<AlbumMember> members(int episodeId);

  /// Pays the reward for every complete episode not paid yet and returns
  /// what was paid (empty if nothing). Never pays an episode twice.
  Future<List<AlbumReward>> claimCompleted();

  /// Fires whenever cards, coins or paid albums change.
  Stream<void> get changes;
}
