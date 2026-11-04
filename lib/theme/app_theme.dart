import 'package:flutter/material.dart';

/// Tokens read from the supplied Figma design system.
abstract final class AppTokens {
  static const primary = Color(0xFF2F6B4F);
  static const primaryContainer = Color(0xFFE1F1E6);
  static const onPrimaryContainer = Color(0xFF183D2D);
  static const canvas = Color(0xFFF7F8F4);
  static const surface = Colors.white;
  static const text = Color(0xFF1F2B24);
  static const secondaryText = Color(0xFF526258);
  static const border = Color(0xFFD6DFD7);
  static const peach = Color(0xFFF4E4D2);
  static const success = Color(0xFF196C46);
  static const shadow = Color(0x1A1A291F);
  static const space4 = 4.0;
  static const space6 = 6.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const pageInset = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const smallRadius = 8.0;
  static const mediumRadius = 12.0;
  static const largeRadius = 20.0;
  static const pillRadius = 999.0;
  static const controlHeight = 52.0;
  static const touchTarget = 48.0;
  static const appBarHeight = 56.0;
  static const cardHeight = 108.0;
  static const heroHeight = 226.0;
  static const contentMaxWidth = 560.0;
  static const iconSize = 32.0;
  static const backIconSize = 26.0;
  static const brandSize = 44.0;
  static const brandActionSize = 40.0;
  static const progressHeight = 8.0;
  static const setupProgressHeight = 6.0;
  static const navHeight = 84.0;
  static const navItemHeight = 68.0;
  static const cardShadow = BoxShadow(
    color: shadow,
    offset: Offset(0, 3),
    blurRadius: 10,
  );
}

abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppTokens.primary,
      onPrimary: Colors.white,
      primaryContainer: AppTokens.primaryContainer,
      onPrimaryContainer: AppTokens.onPrimaryContainer,
      secondary: AppTokens.secondaryText,
      onSecondary: Colors.white,
      surface: AppTokens.surface,
      onSurface: AppTokens.text,
      onSurfaceVariant: AppTokens.secondaryText,
      outline: AppTokens.secondaryText,
      outlineVariant: AppTokens.border,
    );
    const textTheme = TextTheme(
      displaySmall: TextStyle(
        fontSize: 30,
        height: 38 / 30,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 24 / 16),
      bodyMedium: TextStyle(fontSize: 14, height: 20 / 14),
      bodySmall: TextStyle(fontSize: 14, height: 20 / 14),
      labelLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
      ),
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: scheme,
      scaffoldBackgroundColor: AppTokens.canvas,
      textTheme: textTheme.apply(
        bodyColor: AppTokens.text,
        displayColor: AppTokens.text,
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, AppTokens.controlHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space16,
            vertical: AppTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.mediumRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.smallRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTokens.secondaryText),
          borderRadius: BorderRadius.circular(AppTokens.smallRadius),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTokens.border),
          borderRadius: BorderRadius.circular(AppTokens.smallRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTokens.primary, width: 2),
          borderRadius: BorderRadius.circular(AppTokens.smallRadius),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppTokens.primary,
        linearTrackColor: AppTokens.border,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
