import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('tr')];

  /// App name. Kept in English: it is the working title of the game.
  ///
  /// In tr, this message translates to:
  /// **'Portal Cards'**
  String get appTitle;

  /// Splash status line while the first sync downloads data.
  ///
  /// In tr, this message translates to:
  /// **'Evrenler indiriliyor'**
  String get syncInProgress;

  /// Sync progress percentage, Turkish style (sign before the number).
  ///
  /// In tr, this message translates to:
  /// **'%{percent}'**
  String syncPercent(int percent);

  /// Items downloaded out of total during sync.
  ///
  /// In tr, this message translates to:
  /// **'{downloaded} / {total}'**
  String syncCount(int downloaded, int total);

  /// SPEC 2.1 AC3: network failure during sync.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı koptu. Kaldığın yerden devam edeceğiz.'**
  String get syncConnectionError;

  /// Sync failed for a non-network reason (storage or bad data).
  ///
  /// In tr, this message translates to:
  /// **'Veriler kaydedilemedi. Tekrar dene.'**
  String get syncStorageError;

  /// Retry button.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// Main menu screen title; also the label of buttons that go back to it.
  ///
  /// In tr, this message translates to:
  /// **'Ana menü'**
  String get menuTitle;

  /// Portal screen title.
  ///
  /// In tr, this message translates to:
  /// **'Portal'**
  String get portalTitle;

  /// Collection screen title.
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyon'**
  String get collectionTitle;

  /// Card detail screen title. Placeholder until the card name is shown.
  ///
  /// In tr, this message translates to:
  /// **'Kart {id}'**
  String cardDetailTitle(String id);

  /// Deck builder screen title.
  ///
  /// In tr, this message translates to:
  /// **'Deste'**
  String get deckTitle;

  /// Battle screen title.
  ///
  /// In tr, this message translates to:
  /// **'Savaş'**
  String get battleTitle;

  /// Album screen title.
  ///
  /// In tr, this message translates to:
  /// **'Albüm'**
  String get albumTitle;

  /// Album page for one episode. Placeholder until the episode code is shown.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm {episodeId}'**
  String albumPageTitle(String episodeId);

  /// Settings screen title.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// Shown for an unknown route.
  ///
  /// In tr, this message translates to:
  /// **'Sayfa bulunamadı'**
  String get notFoundTitle;

  /// Rarity name: common.
  ///
  /// In tr, this message translates to:
  /// **'Sıradan'**
  String get rarityCommon;

  /// Rarity name: rare.
  ///
  /// In tr, this message translates to:
  /// **'Nadir'**
  String get rarityRare;

  /// Rarity name: epic.
  ///
  /// In tr, this message translates to:
  /// **'Epik'**
  String get rarityEpic;

  /// Rarity name: legendary.
  ///
  /// In tr, this message translates to:
  /// **'Efsanevi'**
  String get rarityLegendary;

  /// Card type: Human (also Humanoid).
  ///
  /// In tr, this message translates to:
  /// **'İnsan'**
  String get typeHuman;

  /// Card type: Robot.
  ///
  /// In tr, this message translates to:
  /// **'Robot'**
  String get typeRobot;

  /// Card type: Alien.
  ///
  /// In tr, this message translates to:
  /// **'Uzaylı'**
  String get typeAlien;

  /// Card type: Beast (API species Animal).
  ///
  /// In tr, this message translates to:
  /// **'Hayvan'**
  String get typeBeast;

  /// Card type: Myth (API species Mythological Creature).
  ///
  /// In tr, this message translates to:
  /// **'Mitik'**
  String get typeMyth;

  /// Card type: Neutral (every other species).
  ///
  /// In tr, this message translates to:
  /// **'Nötr'**
  String get typeNeutral;

  /// Passive of Dead characters.
  ///
  /// In tr, this message translates to:
  /// **'Zombi'**
  String get passiveZombie;

  /// Passive of characters with unknown status.
  ///
  /// In tr, this message translates to:
  /// **'Belirsiz'**
  String get passiveUncertain;

  /// Stat label: HP.
  ///
  /// In tr, this message translates to:
  /// **'Can'**
  String get statHp;

  /// Stat label: attack.
  ///
  /// In tr, this message translates to:
  /// **'Saldırı'**
  String get statAtk;

  /// Stat label: defense.
  ///
  /// In tr, this message translates to:
  /// **'Savunma'**
  String get statDef;

  /// Stat label: speed.
  ///
  /// In tr, this message translates to:
  /// **'Hız'**
  String get statSpd;

  /// Card back fact label: species.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get cardBackSpecies;

  /// Card back fact label: status.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get cardBackStatus;

  /// Card back fact label: origin.
  ///
  /// In tr, this message translates to:
  /// **'Köken'**
  String get cardBackOrigin;

  /// Card back fact label: last known location.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get cardBackLocation;

  /// Card back fact label: number of episodes.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm sayısı'**
  String get cardBackEpisodes;

  /// Debug-only screen title.
  ///
  /// In tr, this message translates to:
  /// **'Kart laboratuvarı'**
  String get cardLabTitle;

  /// Debug card lab when no characters are synced.
  ///
  /// In tr, this message translates to:
  /// **'Önce verileri indir: kart laboratuvarı senkronize karakterleri kullanır.'**
  String get cardLabEmpty;

  /// Primary button on the portal screen.
  ///
  /// In tr, this message translates to:
  /// **'Portalı aç · {cost}'**
  String portalOpenButton(int cost);

  /// First-visit hint above the idle portal (SPEC D4).
  ///
  /// In tr, this message translates to:
  /// **'Telefonu salla!'**
  String get portalShakeHint;

  /// SPEC 2.3 AC2.
  ///
  /// In tr, this message translates to:
  /// **'Portal için {cost} coin gerekli. Savaşarak coin kazan.'**
  String portalNotEnoughCoins(int cost);

  /// Action in the not-enough-coins message.
  ///
  /// In tr, this message translates to:
  /// **'Savaşa git'**
  String get portalGoToBattle;

  /// Hint under the landed card back.
  ///
  /// In tr, this message translates to:
  /// **'Çevirmek için dokun'**
  String get portalTapToFlip;

  /// After a reveal: open another portal.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar aç'**
  String get portalOpenAgain;

  /// After a reveal: go to the collection.
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyona git'**
  String get portalToCollection;

  /// Shown when the card is a duplicate.
  ///
  /// In tr, this message translates to:
  /// **'Zaten vardı · +{coins} coin'**
  String portalDuplicate(int coins);

  /// Shown when the card is new.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kart!'**
  String get portalNewCard;

  /// Accessibility label of the coin counter.
  ///
  /// In tr, this message translates to:
  /// **'{coins} coin'**
  String coinsLabel(int coins);

  /// Portal failed for a storage reason.
  ///
  /// In tr, this message translates to:
  /// **'Portal açılamadı. Tekrar dene.'**
  String get portalError;

  /// Main menu primary action.
  ///
  /// In tr, this message translates to:
  /// **'Portalı aç'**
  String get menuOpenPortal;

  /// Shown while the battle entry is disabled (SPEC 2.2 AC2).
  ///
  /// In tr, this message translates to:
  /// **'Destene 3 kart ekle'**
  String get menuDeckHint;

  /// Count next to a menu entry.
  ///
  /// In tr, this message translates to:
  /// **'{owned}/{total}'**
  String menuCount(int owned, int total);

  /// Settings icon button tooltip.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get menuSettingsTooltip;

  /// SPEC 2.4 AC4.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kartın yok. İlk portalını aç.'**
  String get collectionEmpty;

  /// Filters hide every card.
  ///
  /// In tr, this message translates to:
  /// **'Bu filtreye uyan kart yok.'**
  String get collectionFilteredEmpty;

  /// Filter chip: clear all filters.
  ///
  /// In tr, this message translates to:
  /// **'Hepsi'**
  String get collectionAll;

  /// Sort: rarity, highest first.
  ///
  /// In tr, this message translates to:
  /// **'Nadirlik'**
  String get collectionSortRarity;

  /// Sort: name A to Z.
  ///
  /// In tr, this message translates to:
  /// **'İsim'**
  String get collectionSortName;

  /// Sort: newest first.
  ///
  /// In tr, this message translates to:
  /// **'En yeni'**
  String get collectionSortNewest;

  /// Sort menu tooltip.
  ///
  /// In tr, this message translates to:
  /// **'Sırala'**
  String get collectionSortTooltip;

  /// Card detail action.
  ///
  /// In tr, this message translates to:
  /// **'Desteye ekle'**
  String get deckAdd;

  /// Card detail action.
  ///
  /// In tr, this message translates to:
  /// **'Desteden çıkar'**
  String get deckRemove;

  /// Why adding is disabled.
  ///
  /// In tr, this message translates to:
  /// **'Deste dolu (3/3)'**
  String get deckFull;

  /// Card detail for a card not in the collection.
  ///
  /// In tr, this message translates to:
  /// **'Bu karta henüz sahip değilsin.'**
  String get deckNotOwned;

  /// Deck size chip on the card detail.
  ///
  /// In tr, this message translates to:
  /// **'Deste {count}/3'**
  String deckCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
