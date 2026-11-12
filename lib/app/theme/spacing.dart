import 'package:flutter/painting.dart';

/// Spacing on a 4 dp grid (SPEC §5.4).
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Horizontal screen gutter.
  static const double gutter = md;
}

/// Corner radius by hierarchy, not one value (SPEC §5.4).
abstract final class AppRadius {
  static const double card = 14;
  static const double button = 12;

  /// Top corners of bottom sheets.
  static const double sheet = 24;

  /// Large enough to make any chip a full pill.
  static const double pill = 999;

  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius buttonAll = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Ink outline widths (SPEC §5.4). Outlines are always `AppColors.ink`.
abstract final class AppOutline {
  /// Cards and buttons.
  static const double thick = 2.5;

  /// Chips.
  static const double thin = 2;

  /// Max hand-drawn wobble, drawn only on cards and the primary button.
  static const double wobble = 0.6;
}

/// Hard offset shadow, no blur (SPEC §5.4). Only on interactive raised items.
abstract final class AppDepth {
  /// Shadow offset down-right; a pressed item moves by the same amount.
  static const double shadowOffset = 4;

  static const Offset shadow = Offset(shadowOffset, shadowOffset);
}

/// Fixed component sizes.
abstract final class AppSizes {
  /// Portal on the splash screen (shrinks to fit narrow screens).
  static const double splashPortal = 220;

  /// Height of progress bars.
  static const double progressBar = 12;

  /// Max width of centered content blocks (text, bars, buttons).
  static const double contentMaxWidth = 320;
}
