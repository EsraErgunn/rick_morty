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
}
