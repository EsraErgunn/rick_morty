import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

import '../game/economy.dart';
import 'hive_type_ids.dart';

part 'player_state.g.dart';

// Game state stored in the `player` and `collection` boxes. Field numbers
// are permanent: add new fields with new numbers, never reuse one.

/// Sound, music and haptics toggles + volumes (SPEC §2.9).
@HiveType(typeId: HiveTypeIds.playerSettings)
class PlayerSettings extends Equatable {
  const PlayerSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
    this.sfxVolume = 1,
    this.musicVolume = 1,
  });

  @HiveField(0)
  final bool soundEnabled;
  @HiveField(1)
  final bool musicEnabled;
  @HiveField(2)
  final bool hapticsEnabled;

  /// 0.0 to 1.0.
  @HiveField(3)
  final double sfxVolume;
  @HiveField(4)
  final double musicVolume;

  PlayerSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? hapticsEnabled,
    double? sfxVolume,
    double? musicVolume,
  }) => PlayerSettings(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    musicEnabled: musicEnabled ?? this.musicEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    sfxVolume: sfxVolume ?? this.sfxVolume,
    musicVolume: musicVolume ?? this.musicVolume,
  );

  @override
  List<Object?> get props => [
    soundEnabled,
    musicEnabled,
    hapticsEnabled,
    sfxVolume,
    musicVolume,
  ];
}

/// Everything about the player except the owned cards.
@HiveType(typeId: HiveTypeIds.playerState)
class PlayerState extends Equatable {
  const PlayerState({
    this.coins = EconomyRules.startingCoins,
    this.settings = const PlayerSettings(),
    this.deck = const [],
    this.wins = 0,
    this.portalsOpened = 0,
    this.shakeHintSeen = false,
    this.completedAlbums = const [],
    this.demoUnlocked = false,
    this.forceNextLegendary = false,
    this.syncProgress = const {},
    this.syncTotals = const {},
    this.syncPages = const {},
    this.syncVersion,
    this.syncedAt,
  });

  @HiveField(0)
  final int coins;
  @HiveField(1)
  final PlayerSettings settings;

  /// Character ids in the deck, at most 3.
  @HiveField(2)
  final List<int> deck;
  @HiveField(3)
  final int wins;

  /// All portals ever opened ([GM §7.1] no-duplicate rule).
  @HiveField(4)
  final int portalsOpened;
  @HiveField(5)
  final bool shakeHintSeen;

  /// Episode ids whose album reward was paid.
  @HiveField(6)
  final List<int> completedAlbums;
  @HiveField(7)
  final bool demoUnlocked;
  @HiveField(8)
  final bool forceNextLegendary;

  /// Last completed page per resource (`character`, `episode`, `location`).
  @HiveField(9)
  final Map<String, int> syncProgress;

  /// `info.count` per resource, saved with the first page (progress totals).
  @HiveField(10)
  final Map<String, int> syncTotals;

  /// `info.pages` per resource, saved with the first page.
  @HiveField(13)
  final Map<String, int> syncPages;

  /// Set when a full sync completed; null until then.
  @HiveField(11)
  final int? syncVersion;
  @HiveField(12)
  final DateTime? syncedAt;

  bool get isSynced => syncVersion != null;

  PlayerState copyWith({
    int? coins,
    PlayerSettings? settings,
    List<int>? deck,
    int? wins,
    int? portalsOpened,
    bool? shakeHintSeen,
    List<int>? completedAlbums,
    bool? demoUnlocked,
    bool? forceNextLegendary,
    Map<String, int>? syncProgress,
    Map<String, int>? syncTotals,
    Map<String, int>? syncPages,
    int? syncVersion,
    DateTime? syncedAt,
  }) => PlayerState(
    coins: coins ?? this.coins,
    settings: settings ?? this.settings,
    deck: deck ?? this.deck,
    wins: wins ?? this.wins,
    portalsOpened: portalsOpened ?? this.portalsOpened,
    shakeHintSeen: shakeHintSeen ?? this.shakeHintSeen,
    completedAlbums: completedAlbums ?? this.completedAlbums,
    demoUnlocked: demoUnlocked ?? this.demoUnlocked,
    forceNextLegendary: forceNextLegendary ?? this.forceNextLegendary,
    syncProgress: syncProgress ?? this.syncProgress,
    syncTotals: syncTotals ?? this.syncTotals,
    syncPages: syncPages ?? this.syncPages,
    syncVersion: syncVersion ?? this.syncVersion,
    syncedAt: syncedAt ?? this.syncedAt,
  );

  @override
  List<Object?> get props => [
    coins,
    settings,
    deck,
    wins,
    portalsOpened,
    shakeHintSeen,
    completedAlbums,
    demoUnlocked,
    forceNextLegendary,
    syncProgress,
    syncTotals,
    syncPages,
    syncVersion,
    syncedAt,
  ];
}

/// One owned character in the `collection` box (key: character id).
@HiveType(typeId: HiveTypeIds.ownedCard)
class OwnedCard extends Equatable {
  const OwnedCard({
    required this.characterId,
    required this.copies,
    required this.firstObtainedAt,
  });

  @HiveField(0)
  final int characterId;

  /// Copies received (duplicates count; merge is a stretch goal).
  @HiveField(1)
  final int copies;
  @HiveField(2)
  final DateTime firstObtainedAt;

  @override
  List<Object?> get props => [characterId, copies, firstObtainedAt];
}
