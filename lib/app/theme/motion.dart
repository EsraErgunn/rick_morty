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

  /// Pop-in of new elements.
  static const Curve popIn = Curves.easeOutBack;

  /// Movement between positions, card flip.
  static const Curve move = Curves.easeInOutCubic;

  /// Rewards (coins, victory).
  static const Curve reward = Curves.elasticOut;

  /// Perspective entry for 3D rotations: `Matrix4..setEntry(3, 2, perspective)`.
  static const double perspective = 0.001;
}
