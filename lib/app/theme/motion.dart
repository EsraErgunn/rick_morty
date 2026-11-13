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
  /// Longest the splash waits for the loader to close after a successful
  /// sync (min visible + close + margin); then it navigates anyway.
  static const Duration splashExitLimit = Duration(milliseconds: 1500);

  /// A shader that does not load and warm up within this falls back to
  /// its static drawing.
  static const Duration shaderLoadLimit = Duration(seconds: 3);

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

  /// Menu items enter one after another (SPEC §4.2).
  static const Duration stagger = Duration(milliseconds: 40);

  /// Empty-collection call to action breathes (scale 1.0 to 1.04).
  static const Duration breathe = Duration(milliseconds: 1200);
  static const double breatheScale = 1.04;

  /// Demo unlock: taps on the version label must fall in this window (D2).
  static const Duration demoTapWindow = Duration(seconds: 3);

  /// Pop-in of new elements.
  /// Battle (SPEC §4.7): cards deal in with this stagger.
  static const Duration battleDealStagger = Duration(milliseconds: 80);

  /// Gap after each replayed event; a whole turn stays ≤ 1.6 s.
  static const Duration battleGap = fast;

  /// A hit, dodge or faint holds the replay this long (`normal` + gap).
  static const Duration battleHit = Duration(milliseconds: 450);

  /// Reduced motion: every replay step is a short fade.
  static const Duration battleReduced = fast;

  /// The 2× toggle divides replay durations by this.
  static const int battleFastFactor = 2;

  /// Attack: wind-up, leap, impact, return. The hit event starts at
  /// [battleAttackImpact], while the attacker is still on the target.
  static const Duration battleAttack = Duration(milliseconds: 700);
  static const Duration battleAttackImpact = Duration(milliseconds: 400);

  /// Crit / super-effective hit: bigger shake and flashing light.
  static const Duration battleHeavyHit = slow;

  /// Faint: the card spins, shrinks and is pulled into a small portal.
  static const Duration battleFaint = Duration(milliseconds: 900);

  /// Victory: the winners hop one after another.
  static const Duration battleVictory = Duration(milliseconds: 1200);
  static const Duration battleVictoryStagger = Duration(milliseconds: 160);

  /// Rick's 2.5D victory / defeat reaction (cut-out leaves the card). The
  /// battle end holds the replay this long so the reaction can finish.
  static const Duration battleRickReaction = Duration(milliseconds: 2000);

  /// Idle float of a battle card (one up-down cycle); phases differ per slot.
  static const Duration battleIdle = Duration(milliseconds: 2400);

  /// Gentle float of cards in the collection and deck grids.
  static const Duration gridFloat = Duration(milliseconds: 3200);

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
