import 'package:flutter/material.dart';

import 'colors.dart';
import 'motion.dart';
import 'spacing.dart';
import 'typography.dart';

/// The single dark theme of the app, built only from tokens.
abstract final class AppTheme {
  static const ColorScheme _scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.portal,
    onPrimary: AppColors.ink,
    secondary: AppColors.portalHot,
    onSecondary: AppColors.ink,
    error: AppColors.danger,
    onError: AppColors.ink,
    surface: AppColors.voidRaised,
    onSurface: AppColors.paper,
    onSurfaceVariant: AppColors.paperMuted,
    outline: AppColors.ink,
    shadow: AppColors.ink,
  );

  static const TextTheme _textTheme = TextTheme(
    displayLarge: AppTypography.callout,
    displayMedium: AppTypography.display,
    headlineMedium: AppTypography.headline,
    titleLarge: AppTypography.title,
    titleMedium: AppTypography.label,
    bodyLarge: AppTypography.body,
    bodyMedium: AppTypography.body,
    bodySmall: AppTypography.caption,
    labelLarge: AppTypography.label,
    labelSmall: AppTypography.caption,
  );

  static const BorderSide _outline = BorderSide(
    color: AppColors.ink,
    width: AppOutline.thick,
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: _scheme,
    scaffoldBackgroundColor: AppColors.voidBase,
    canvasColor: AppColors.voidBase,
    fontFamily: AppFonts.body,
    textTheme: _textTheme,
    focusColor: AppColors.portalHot,
    iconTheme: const IconThemeData(color: AppColors.paper),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.voidBase,
      foregroundColor: AppColors.paper,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.headline,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.portal,
        foregroundColor: AppColors.ink,
        textStyle: AppTypography.label,
        minimumSize: const Size.square(AppSpacing.xxl),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonAll,
          side: _outline,
        ),
        elevation: 0,
        animationDuration: AppMotion.fast,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.paper,
        textStyle: AppTypography.label,
        minimumSize: const Size.square(AppSpacing.xxl),
        side: const BorderSide(color: AppColors.paper, width: AppOutline.thin),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonAll),
        animationDuration: AppMotion.fast,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.voidRaised,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: _outline,
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.voidRaised,
      selectedColor: AppColors.portal,
      labelStyle: AppTypography.label,
      side: BorderSide(color: AppColors.ink, width: AppOutline.thin),
      shape: StadiumBorder(),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.voidRaised,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.voidRaised,
      titleTextStyle: AppTypography.headline,
      contentTextStyle: AppTypography.body,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: _outline,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.portal,
      linearTrackColor: AppColors.voidRaised,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.paper,
      contentTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: AppTypography.bodySize,
        color: AppColors.ink,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
