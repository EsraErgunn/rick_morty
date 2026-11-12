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
}
