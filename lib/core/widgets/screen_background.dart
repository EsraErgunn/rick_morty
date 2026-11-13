import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// Bir ekranın arkasındaki tam ekran görsel (SPEC §5.9, D9). Görsel ekranı
/// kaplar (merkezi ekran merkezinde kalır). [scrim] üstte ve altta koyu bir
/// `void` geçişi ekler, böylece yazı okunur kalır (proje sahibinin
/// isteği 2026-11-12; shader'lar dışındaki tek geçiş).
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

  /// Örtünün en üstte/altta ne kadar koyulaştığı ve ne kadar uzağa uzandığı.
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

/// Arka planların görsel dosya yolları (tools/images ile dönüştürüldü).
abstract final class Backgrounds {
  static const String menu = 'assets/images/menu_bg.webp';
  static const String splash = 'assets/images/splash_bg.webp';

  /// Savaş arenası: portal, iki parlayan platform, çatlamış uzaylı zemini.
  static const String battle = 'assets/images/battle_bg.webp';
}
