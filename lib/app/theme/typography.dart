import 'package:flutter/painting.dart';

import 'colors.dart';

/// Font families bundled under `assets/fonts/` (SPEC §5.3).
abstract final class AppFonts {
  /// Display: screen titles, card names, battle callouts. Weights 700, 900.
  static const String display = 'Grandstander';

  /// Body and numbers: stats, lists, settings. Weights 400, 700.
  static const String body = 'AtkinsonHyperlegibleNext';
}

/// Type scale in sp, ratio 1.25, body 16 (SPEC §5.3).
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

  /// Buttons and emphasized body text.
  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: bodySize,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.paper,
  );

  /// Card names, section titles.
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

  /// Screen titles.
  static const TextStyle display = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: displaySize,
    fontWeight: FontWeight.w900,
    height: 1.1,
    color: AppColors.paper,
  );

  /// Battle callouts and the legendary name.
  static const TextStyle callout = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: calloutSize,
    fontWeight: FontWeight.w900,
    height: 1,
    color: AppColors.paper,
  );

  /// Stat values on cards and in battle. Tabular so digits do not jump.
  static const TextStyle stat = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: bodySize,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.paper,
    fontFeatures: _tabular,
  );

  /// Coin counter. Tabular so the width stays stable while it counts.
  static const TextStyle coin = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: titleSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.paper,
    fontFeatures: _tabular,
  );
}
