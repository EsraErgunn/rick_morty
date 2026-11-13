import 'package:flutter/painting.dart';

/// Color tokens from SPEC §5.2 ("Cel ink in the void").
///
/// Measured WCAG contrast ratios are recorded in SPEC §5.2 and checked by
/// `test/app/theme/contrast_test.dart`. Text on any colored fill (portal,
/// warn, danger, rarity frames) uses [ink], never [paper].
abstract final class AppColors {
  /// SPEC token `void` (renamed: `void` is a Dart keyword).
  /// App background: deep space indigo.
  static const Color voidBase = Color(0xFF15112B);

  /// Surfaces: panels, slots, sheets, card body.
  static const Color voidRaised = Color(0xFF231B45);

  /// Outlines and hard shadows; text on colored fills.
  static const Color ink = Color(0xFF0B0918);

  /// Primary text on [voidBase], card name plates.
  static const Color paper = Color(0xFFF2ECDF);

  /// Secondary text.
  static const Color paperMuted = Color(0xFFA9A3BF);

  /// The only accent: portal, primary action, selection, progress.
  static const Color portal = Color(0xFF8FE04A);

  /// Portal core highlight, focus ring.
  static const Color portalHot = Color(0xFFD4FF7A);

  /// Legendary portal, destructive actions, low HP.
  static const Color danger = Color(0xFFFF5A4E);

  /// HP at or below 50%. Orange, kept apart from [rarityLegendary] gold.
  static const Color warn = Color(0xFFFF9F43);

  /// Rarity frame colors [GM §2]. Semantic: they mean rarity only.
  static const Color rarityCommon = Color(0xFF9AA5B1);
  static const Color rarityRare = Color(0xFF3FA9F5);
  static const Color rarityEpic = Color(0xFFA55EEA);
  static const Color rarityLegendary = Color(0xFFF7B731);
}
