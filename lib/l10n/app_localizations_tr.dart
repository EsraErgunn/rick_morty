// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Portal Cards';

  @override
  String get syncInProgress => 'Evrenler indiriliyor';

  @override
  String syncPercent(int percent) {
    return '%$percent';
  }

  @override
  String syncCount(int downloaded, int total) {
    return '$downloaded / $total';
  }

  @override
  String get syncConnectionError =>
      'Bağlantı koptu. Kaldığın yerden devam edeceğiz.';

  @override
  String get syncStorageError => 'Veriler kaydedilemedi. Tekrar dene.';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get menuTitle => 'Ana menü';

  @override
  String get portalTitle => 'Portal';

  @override
  String get collectionTitle => 'Koleksiyon';

  @override
  String cardDetailTitle(String id) {
    return 'Kart $id';
  }

  @override
  String get deckTitle => 'Deste';

  @override
  String get battleTitle => 'Savaş';

  @override
  String get albumTitle => 'Albüm';

  @override
  String albumPageTitle(String episodeId) {
    return 'Bölüm $episodeId';
  }

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get notFoundTitle => 'Sayfa bulunamadı';

  @override
  String get rarityCommon => 'Sıradan';

  @override
  String get rarityRare => 'Nadir';

  @override
  String get rarityEpic => 'Epik';

  @override
  String get rarityLegendary => 'Efsanevi';

  @override
  String get typeHuman => 'İnsan';

  @override
  String get typeRobot => 'Robot';

  @override
  String get typeAlien => 'Uzaylı';

  @override
  String get typeBeast => 'Hayvan';

  @override
  String get typeMyth => 'Mitik';

  @override
  String get typeNeutral => 'Nötr';

  @override
  String get passiveZombie => 'Zombi';

  @override
  String get passiveUncertain => 'Belirsiz';

  @override
  String get statHp => 'Can';

  @override
  String get statAtk => 'Saldırı';

  @override
  String get statDef => 'Savunma';

  @override
  String get statSpd => 'Hız';

  @override
  String get cardBackSpecies => 'Tür';

  @override
  String get cardBackStatus => 'Durum';

  @override
  String get cardBackOrigin => 'Köken';

  @override
  String get cardBackLocation => 'Konum';

  @override
  String get cardBackEpisodes => 'Bölüm sayısı';

  @override
  String get cardLabTitle => 'Kart laboratuvarı';

  @override
  String get cardLabEmpty =>
      'Önce verileri indir: kart laboratuvarı senkronize karakterleri kullanır.';

  @override
  String portalOpenButton(int cost) {
    return 'Portalı aç · $cost';
  }

  @override
  String get portalShakeHint => 'Telefonu salla!';

  @override
  String portalNotEnoughCoins(int cost) {
    return 'Portal için $cost coin gerekli. Savaşarak coin kazan.';
  }

  @override
  String get portalGoToBattle => 'Savaşa git';

  @override
  String get portalTapToFlip => 'Çevirmek için dokun';

  @override
  String get portalOpenAgain => 'Tekrar aç';

  @override
  String get portalToCollection => 'Koleksiyona git';

  @override
  String portalDuplicate(int coins) {
    return 'Zaten vardı · +$coins coin';
  }

  @override
  String get portalNewCard => 'Yeni kart!';

  @override
  String coinsLabel(int coins) {
    return '$coins coin';
  }

  @override
  String get portalError => 'Portal açılamadı. Tekrar dene.';

  @override
  String get menuOpenPortal => 'Portalı aç';

  @override
  String get menuDeckHint => 'Destene 3 kart ekle';

  @override
  String menuCount(int owned, int total) {
    return '$owned/$total';
  }

  @override
  String get menuSettingsTooltip => 'Ayarlar';

  @override
  String get collectionEmpty => 'Henüz kartın yok. İlk portalını aç.';

  @override
  String get collectionFilteredEmpty => 'Bu filtreye uyan kart yok.';

  @override
  String get collectionAll => 'Hepsi';

  @override
  String get collectionSortRarity => 'Nadirlik';

  @override
  String get collectionSortName => 'İsim';

  @override
  String get collectionSortNewest => 'En yeni';

  @override
  String get collectionSortTooltip => 'Sırala';

  @override
  String get deckAdd => 'Desteye ekle';

  @override
  String get deckRemove => 'Desteden çıkar';

  @override
  String get deckFull => 'Deste dolu (3/3)';

  @override
  String get deckNotOwned => 'Bu karta henüz sahip değilsin.';

  @override
  String deckCount(int count) {
    return 'Deste $count/3';
  }

  @override
  String get signatureGenius => 'Dahi';

  @override
  String get signatureAwJeez => 'Aman tanrım!';

  @override
  String get signatureTeamSpirit => 'Takım ruhu';

  @override
  String get signatureMissionComplete => 'Görev tamam';

  @override
  String get signaturePickleArmor => 'Turşu zırhı';

  @override
  String get cardBackSignature => 'İmza yeteneği';

  @override
  String get featuredBadge => 'Öne çıkan karakter';

  @override
  String featuredCallout(String name) {
    return '$name!';
  }

  @override
  String get settingsSound => 'Ses efektleri';

  @override
  String get settingsMusic => 'Müzik';

  @override
  String get settingsHaptics => 'Titreşim';

  @override
  String get settingsSfxVolume => 'Efekt sesi';

  @override
  String get settingsMusicVolume => 'Müzik sesi';

  @override
  String settingsVersion(String version) {
    return 'Sürüm $version';
  }

  @override
  String get settingsDemoTitle => 'Demo paneli';

  @override
  String get settingsDemoCoins => '+1000 coin';

  @override
  String get settingsDemoLegendary => 'Sonraki portal Legendary';

  @override
  String get settingsDemoLegendaryArmed => 'Sonraki portal Legendary: hazır';

  @override
  String get settingsDemoOff => 'Demo modunu kapat';

  @override
  String get settingsReset => 'İlerlemeyi sıfırla';

  @override
  String get settingsResetTitle => 'İlerleme sıfırlansın mı?';

  @override
  String get settingsResetBody =>
      'Coinler, kartlar, deste ve ilerleme silinir. İndirilen karakter verileri kalır.';

  @override
  String get settingsResetConfirm => 'Sıfırla';

  @override
  String get settingsCancel => 'Vazgeç';

  @override
  String get settingsResetDone => 'İlerleme sıfırlandı.';

  @override
  String get settingsDisclaimer =>
      'Portal Cards, ticari olmayan bir hayran projesidir. Rick and Morty karakterleri ve görselleri Adult Swim\'e aittir. Veriler: rickandmortyapi.com.';

  @override
  String get settingsCredits =>
      'Tüm sesler ve müzikler tools/audio ile prosedürel olarak üretildi.';

  @override
  String get settingsImages => 'Tüm görselleri çevrimdışı için indir';

  @override
  String settingsImagesProgress(int percent, int done, int total) {
    return '%$percent · $done/$total';
  }

  @override
  String get settingsImagesStop => 'Durdur';

  @override
  String get settingsImagesDone => 'İndirildi';

  @override
  String settingsImagesFailed(int count) {
    return '$count görsel indirilemedi. Tekrar dene.';
  }

  @override
  String get settingsImagesStopped =>
      'Durduruldu. Devam etmek için tekrar başlat.';

  @override
  String get deckSlotEmpty => 'Boş';

  @override
  String deckTotals(int hp, int atk, int def, int spd) {
    return 'Can $hp · Saldırı $atk · Savunma $def · Hız $spd';
  }

  @override
  String get deckCoverage => 'Tip üçgeni';

  @override
  String get deckNoCards => 'Henüz kartın yok. Önce portal aç.';

  @override
  String get deckHint => 'Karta dokun: desteye ekle. Slota dokun: çıkar.';

  @override
  String get battleStart => 'Başla';

  @override
  String get battleOpponent => 'Rakip';

  @override
  String get battleYourDeck => 'Destem';

  @override
  String battleTier(int tier, int wins) {
    return 'Kademe $tier · $wins galibiyet';
  }

  @override
  String get battleYourTurn => 'Senin sıran: saldıracak kartı seç';

  @override
  String get battlePickTarget => 'Hedefi seç';

  @override
  String get battleEnemyTurn => 'Rakip düşünüyor';

  @override
  String get battleCrit => 'KRİTİK!';

  @override
  String get battleGenius => 'DAHİ!';

  @override
  String get battleSuperEffective => 'SÜPER ETKİLİ!';

  @override
  String get battleNotEffective => 'Pek etkili değil…';

  @override
  String get battleDodge => 'KAÇTI!';

  @override
  String get battleRevive => 'Zombi! Geri döndü';

  @override
  String get battleVictory => 'Kazandın!';

  @override
  String get battleDefeat => 'Kaybettin';

  @override
  String get battleDraw => 'Berabere';

  @override
  String battleReward(int coins) {
    return '+$coins coin';
  }

  @override
  String battleTierUp(int tier) {
    return 'Kademe atladın! Artık kademe $tier';
  }

  @override
  String get battleAgain => 'Yeni savaş';

  @override
  String get battleBackToMenu => 'Menüye dön';

  @override
  String get battleLeaveTitle => 'Savaştan çıkılsın mı?';

  @override
  String get battleLeaveBody => 'Bu savaş yenilgi sayılır.';

  @override
  String get battleLeaveConfirm => 'Çık';

  @override
  String get battleLeaveCancel => 'Devam et';

  @override
  String get battleNoDeck => 'Savaşmak için destende 3 kart olmalı.';

  @override
  String get battleGoToDeck => 'Desteye git';

  @override
  String get battleSpeed => '2×';

  @override
  String get battleLeave => 'Savaştan çık';
}
