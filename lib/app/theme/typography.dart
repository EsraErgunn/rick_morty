import 'package:flutter/painting.dart';

import 'colors.dart';

/// `assets/fonts/` altına paketlenmiş yazı tipi aileleri (SPEC §5.3).
abstract final class AppFonts {
  /// Display: ekran başlıkları, kart isimleri, savaş duyuruları. Kalınlıklar 700, 900.
  static const String display = 'Grandstander';

  /// Gövde ve sayılar: istatistikler, listeler, ayarlar. Kalınlıklar 400, 700.
  static const String body = 'AtkinsonHyperlegibleNext';
}

/// sp cinsinden yazı ölçeği, oran 1.25, gövde 16 (SPEC §5.3).
abstract final class AppTypography {
  static const double captionSize = 12;
  static const double bodySize = 16;
  static const double titleSize = 20;
  static const double headlineSize = 25;
  static const double displaySize = 40;
  static const double calloutSize = 56;

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: captionSize,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.paperMuted,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: bodySize,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.paper,
  );

  /// Butonlar ve vurgulu gövde yazısı.
  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: bodySize,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.paper,
  );

  /// Kart isimleri, bölüm başlıkları.
  static const TextStyle title = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: titleSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.paper,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: headlineSize,
    fontWeight: FontWeight.w900,
    height: 1.15,
    color: AppColors.paper,
  );

  /// Ekran başlıkları.
  static const TextStyle display = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: displaySize,
    fontWeight: FontWeight.w900,
    height: 1.1,
    color: AppColors.paper,
  );

  /// Savaş duyuruları ve efsanevi isim.
  static const TextStyle callout = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: calloutSize,
    fontWeight: FontWeight.w900,
    height: 1,
    color: AppColors.paper,
  );

  /// Kartlarda ve savaşta istatistik değerleri. Tablo rakamlı, rakamlar zıplamasın.
  static const TextStyle stat = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: bodySize,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.paper,
    fontFeatures: _tabular,
  );

  /// Coin sayacı. Tablo rakamlı, sayarken genişlik sabit kalsın.
  static const TextStyle coin = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: titleSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.paper,
    fontFeatures: _tabular,
  );
}
