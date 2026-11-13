import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

import '../game/economy.dart';
import 'hive_type_ids.dart';

part 'player_state.g.dart';

// `player` ve `collection` kutularında saklanan oyun durumu. Alan numaraları
// kalıcıdır: yeni alanları yeni numaralarla ekle, hiçbirini yeniden kullanma.

/// Ses, müzik ve titreşim anahtarları + ses seviyeleri (SPEC §2.9).
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

  /// 0.0 ile 1.0 arası.
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

/// Sahip olunan kartlar dışında oyuncuyla ilgili her şey.
@HiveType(typeId: HiveTypeIds.playerState)
class PlayerState extends Equatable {
  const PlayerState({
    this.coins = EconomyRules.startingCoins,
    this.settings = const PlayerSettings(),
    this.deck = const [],
    this.wins = 0,
    this.portalsOpened = 0,
    this.shakeHintSeen = false,
    this.onboardingSeen = false,
    this.godMode = false,
    this.completedAlbums = const [],
    this.demoUnlocked = false,
    this.forceNextLegendary = false,
    this.syncProgress = const {},
    this.syncTotals = const {},
    this.syncPages = const {},
    this.syncVersion,
    this.lastBattleId,
    this.syncedAt,
  });

  @HiveField(0)
  final int coins;
  @HiveField(1)
  final PlayerSettings settings;

  /// Destedeki karakter id'leri, en fazla 3.
  @HiveField(2)
  final List<int> deck;
  @HiveField(3)
  final int wins;

  /// Şimdiye kadar açılan tüm portallar ([GM §7.1] tekrar yok kuralı).
  @HiveField(4)
  final int portalsOpened;
  @HiveField(5)
  final bool shakeHintSeen;

  /// İlk açılış tanıtımı bir kez gösterildi (ya da geçildi).
  @HiveField(15)
  final bool onboardingSeen;

  // HiveField 16 kullanılmaz: geri alınan "ilk portal Rick" kuralında
  // kullanıldı, alan numaraları asla yeniden kullanılmaz.

  /// God mode açık: tüm kartlar, sınırsız coin, her portal efsanevi, en
  /// yüksek kademe [GM §7.2]. Gerçek durum `GodModeStore` içinde yedekli.
  @HiveField(17)
  final bool godMode;

  /// Albüm ödülü ödenmiş bölüm id'leri.
  @HiveField(6)
  final List<int> completedAlbums;
  @HiveField(7)
  final bool demoUnlocked;
  @HiveField(8)
  final bool forceNextLegendary;

  /// Kaynak başına son tamamlanan sayfa (`character`, `episode`, `location`).
  @HiveField(9)
  final Map<String, int> syncProgress;

  /// Kaynak başına `info.count`, ilk sayfayla birlikte kaydedilir (ilerleme toplamları).
  @HiveField(10)
  final Map<String, int> syncTotals;

  /// Kaynak başına `info.pages`, ilk sayfayla birlikte kaydedilir.
  @HiveField(13)
  final Map<String, int> syncPages;

  /// Ödülü ödenmiş son savaşın id'si (ödüller tam olarak bir kez).
  @HiveField(14)
  final String? lastBattleId;

  /// Tam bir senkron bitince dolar; o zamana kadar null.
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
    bool? onboardingSeen,
    bool? godMode,
    List<int>? completedAlbums,
    bool? demoUnlocked,
    bool? forceNextLegendary,
    Map<String, int>? syncProgress,
    Map<String, int>? syncTotals,
    Map<String, int>? syncPages,
    int? syncVersion,
    DateTime? syncedAt,
    String? lastBattleId,
  }) => PlayerState(
    coins: coins ?? this.coins,
    settings: settings ?? this.settings,
    deck: deck ?? this.deck,
    wins: wins ?? this.wins,
    portalsOpened: portalsOpened ?? this.portalsOpened,
    shakeHintSeen: shakeHintSeen ?? this.shakeHintSeen,
    onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    godMode: godMode ?? this.godMode,
    completedAlbums: completedAlbums ?? this.completedAlbums,
    demoUnlocked: demoUnlocked ?? this.demoUnlocked,
    forceNextLegendary: forceNextLegendary ?? this.forceNextLegendary,
    syncProgress: syncProgress ?? this.syncProgress,
    syncTotals: syncTotals ?? this.syncTotals,
    syncPages: syncPages ?? this.syncPages,
    syncVersion: syncVersion ?? this.syncVersion,
    syncedAt: syncedAt ?? this.syncedAt,
    lastBattleId: lastBattleId ?? this.lastBattleId,
  );

  @override
  List<Object?> get props => [
    coins,
    settings,
    deck,
    wins,
    portalsOpened,
    shakeHintSeen,
    onboardingSeen,
    godMode,
    completedAlbums,
    demoUnlocked,
    forceNextLegendary,
    syncProgress,
    syncTotals,
    syncPages,
    syncVersion,
    syncedAt,
    lastBattleId,
  ];
}

/// `collection` kutusunda sahip olunan bir karakter (anahtar: karakter id'si).
@HiveType(typeId: HiveTypeIds.ownedCard)
class OwnedCard extends Equatable {
  const OwnedCard({
    required this.characterId,
    required this.copies,
    required this.firstObtainedAt,
  });

  @HiveField(0)
  final int characterId;

  /// Alınan kopyalar (tekrarlar da sayılır; birleştirme ek bir hedef).
  @HiveField(1)
  final int copies;
  @HiveField(2)
  final DateTime firstObtainedAt;

  @override
  List<Object?> get props => [characterId, copies, firstObtainedAt];
}
