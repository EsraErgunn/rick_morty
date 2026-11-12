import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// Full-screen art behind a screen (SPEC §5.9, D9). The image covers the
/// screen (its center stays at the screen center). [scrim] adds a dark
/// `void` gradient at the top and bottom so text stays readable (owner
/// request 2026-11-12; the only gradient besides the shaders).
class ScreenBackground extends StatelessWidget {
  const ScreenBackground({
    required this.asset,
    required this.child,
    this.scrim = false,
    super.key,
  });

  final String asset;
  final Widget child;
  final bool scrim;

  /// How dark the scrim gets at the very top/bottom, and how far it reaches.
  static const double scrimAlpha = 0.9;
  static const double scrimReach = 0.3;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const ColoredBox(color: AppColors.voidBase),
      Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
      if (scrim)
        DecoratedBox(
          key: const ValueKey('background-scrim'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.voidBase.withValues(alpha: scrimAlpha),
                AppColors.voidBase.withValues(alpha: 0),
                AppColors.voidBase.withValues(alpha: 0),
                AppColors.voidBase.withValues(alpha: scrimAlpha),
              ],
              stops: const [0, scrimReach, 1 - scrimReach, 1],
            ),
          ),
        ),
      child,
    ],
  );
}

/// Asset paths of the backgrounds (converted by tools/images).
abstract final class Backgrounds {
  static const String menu = 'assets/images/menu_bg.webp';
  static const String splash = 'assets/images/splash_bg.webp';
}
