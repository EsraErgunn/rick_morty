import 'package:equatable/equatable.dart';

import '../../domain/album_repository.dart';

enum AlbumStatus { initial, success }

/// The album list: episodes sorted by code, plus the rewards paid last.
final class AlbumState extends Equatable {
  const AlbumState({
    this.status = AlbumStatus.initial,
    this.episodes = const [],
    this.rewards = const [],
    this.rewardTick = 0,
  });

  final AlbumStatus status;
  final List<AlbumEpisode> episodes;

  /// Paid in the last claim; the page announces them when [rewardTick]
  /// changes.
  final List<AlbumReward> rewards;
  final int rewardTick;

  int get completed => episodes.where((e) => e.complete).length;

  /// Episodes grouped by season, in order.
  Map<int, List<AlbumEpisode>> get seasons {
    final map = <int, List<AlbumEpisode>>{};
    for (final e in episodes) {
      (map[e.season] ??= []).add(e);
    }
    return map;
  }

  AlbumState copyWith({
    AlbumStatus? status,
    List<AlbumEpisode>? episodes,
    List<AlbumReward>? rewards,
    int? rewardTick,
  }) => AlbumState(
    status: status ?? this.status,
    episodes: episodes ?? this.episodes,
    rewards: rewards ?? this.rewards,
    rewardTick: rewardTick ?? this.rewardTick,
  );

  @override
  List<Object?> get props => [status, episodes, rewards, rewardTick];
}

/// One episode page: its characters, owned or not.
final class AlbumPageState extends Equatable {
  const AlbumPageState({
    this.status = AlbumStatus.initial,
    this.episode,
    this.members = const [],
  });

  final AlbumStatus status;
  final AlbumEpisode? episode;
  final List<AlbumMember> members;

  @override
  List<Object?> get props => [status, episode, members];
}
