import 'package:flutter/animation.dart';

/// Animation tokens (animation rules, `.claude/rules/animation-audio.md`).
///
/// Widgets never use raw durations or curves; they read them from here.
abstract final class AppMotion {
  /// Taps, toggles, small state changes.
  static const Duration fast = Duration(milliseconds: 150);

  /// Moves, card flip, screen-level transitions.
  static const Duration normal = Duration(milliseconds: 300);

  /// Reveals and emphasis.
  static const Duration slow = Duration(milliseconds: 600);

  /// Portal opening, legendary reveal. The minimum; sequences may run longer.
  static const Duration cinematic = Duration(milliseconds: 1500);

  /// A loader is shown only if loading takes longer than this (no flicker).
  static const Duration loaderShowDelay = Duration(milliseconds: 300);

  /// Once shown, a loader stays at least this long.
  static const Duration loaderMinVisible = slow;

  /// One full turn of the waiting portal.
  static const Duration portalSpin = Duration(milliseconds: 3200);

  /// Shake hint: one swing; three swings then [hintPause] (SPEC §4.3).
  static const Duration hintSwing = normal;
  static const Duration hintPause = Duration(milliseconds: 1200);

  /// Coin counter shake when a portal is not affordable (3 cycles).
  static const Duration coinShake = normal;

  /// Reveal scene (SPEC §4.3, D7).
  static const Duration revealCharge = slow;
  static const Duration revealBurst = fast;
  static const Duration revealEmerge = slow;
  static const Duration revealEmergeLegendary = cinematic;
  static const Duration revealFall = normal;
  static const Duration revealSquash = fast;
  static const Duration revealHintDelay = Duration(milliseconds: 1500);
  static const Duration revealAutoFlip = Duration(milliseconds: 4000);
  static const Duration revealHover = Duration(milliseconds: 1200);

  /// Reduced motion: the whole reveal is one crossfade.
  static const Duration revealReduced = slow;

  /// Pop-in of new elements.
  static const Curve popIn = Curves.easeOutBack;

  /// Movement between positions, card flip.
  static const Curve move = Curves.easeInOutCubic;

  /// Rewards (coins, victory).
  static const Curve reward = Curves.elasticOut;

  /// Falling under gravity (quadratic ease-in).
  static const Curve fall = Curves.easeInQuad;

  /// Something coming out of the portal depth.
  static const Curve emerge = Curves.easeOutCubic;

  /// Perspective entry for 3D rotations: `Matrix4..setEntry(3, 2, perspective)`.
  static const double perspective = 0.001;
}
