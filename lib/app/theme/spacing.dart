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

  /// Portal on the portal screen (shrinks on small screens).
  static const double portalHero = 300;

  /// Card width in the reveal scene.
  static const double revealCard = 200;

  /// Screen shake amplitude on the portal burst (SPEC §4.3).
  static const double screenShake = 6;

  /// Coin counter shake amplitude.
  static const double coinShake = 8;

  /// Hover bob of the landed card.
  static const double hoverBob = 2;

  /// Icon sizes.
  /// Battle: selected card lift, attack lunge, damage number rise,
  /// faint drop, HP bar height.
  static const double battleLift = 8;
  static const double battleLunge = 28;
  static const double battleNumberRise = 40;
  static const double battleFaintDrop = 12;
  static const double battleFaintTilt = 0.12;

  /// Battle character animation (SPEC §4.7, delivery polish).
  static const double battleIdleFloat = 5;
  static const double gridFloat = 3;
  static const double battleWindUp = 14;
  static const double battleDash = 84;
  static const double battleHop = 22;
  static const double battleLungeSpin = 0.14;
  static const double battleSquash = 0.16;
  static const double battleHitShake = 10;
  static const double battleCritShake = 20;
  static const double battleKnockTilt = 0.2;
  static const double battleVictoryHop = 28;
  static const double battleParticle = 7;
  static const double battleParticleSpread = 56;
  static const double battleStageShake = 7;
  static const double battleStageCritShake = 14;

  /// Rick's battle reaction (design units of the card).
  static const double rickLeap = 110;
  static const double rickLeapScale = 0.4;
  static const double rickSink = 40;
  static const double rickSquash = 0.25;
  static const double rickTopple = 1.2;
  static const double rickToppleShift = 24;
  static const double rickBubbleWidth = 150;
  static const double rickBubbleTail = 10;
  static const double confettiSize = 6;
  static const double confettiSpread = 150;
  static const double confettiFall = 180;

  /// First-launch intro (onboarding).
  static const double onboardingArt = 260;
  static const double onboardingPortal = 180;
  static const double onboardingCard = 96;
  static const double onboardingHeroCard = 140;
  static const double onboardingFanTilt = 0.18;
  static const double onboardingTypeDisc = 64;
  static const double onboardingDot = 8;
  static const double onboardingDotActive = 24;
  static const double onboardingWiggle = 0.25;

  static const double hpBar = 8;

  /// Minimum touch target (Material / accessibility).
  static const double minTouch = 48;

  static const double iconSmall = 20;
  static const double iconLarge = 40;
}
