import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.contentMaxWidth,
    required this.cardRadius,
    required this.pagePadding,
    required this.sectionSpacing,
  });

  final double contentMaxWidth;
  final double cardRadius;
  final double pagePadding;
  final double sectionSpacing;

  static const fallback = AppThemeTokens(
    contentMaxWidth: 960,
    cardRadius: 28,
    pagePadding: 24,
    sectionSpacing: 24,
  );

  static const light = AppThemeTokens(
    contentMaxWidth: 960,
    cardRadius: 28,
    pagePadding: 24,
    sectionSpacing: 24,
  );

  static const dark = AppThemeTokens(
    contentMaxWidth: 960,
    cardRadius: 28,
    pagePadding: 24,
    sectionSpacing: 24,
  );

  @override
  AppThemeTokens copyWith({
    double? contentMaxWidth,
    double? cardRadius,
    double? pagePadding,
    double? sectionSpacing,
  }) {
    return AppThemeTokens(
      contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
      cardRadius: cardRadius ?? this.cardRadius,
      pagePadding: pagePadding ?? this.pagePadding,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) {
      return this;
    }

    return AppThemeTokens(
      contentMaxWidth: lerpDouble(contentMaxWidth, other.contentMaxWidth, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      pagePadding: lerpDouble(pagePadding, other.pagePadding, t)!,
      sectionSpacing: lerpDouble(sectionSpacing, other.sectionSpacing, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static AppThemeTokens of(BuildContext context) {
    return Theme.of(context).extension<AppThemeTokens>() ??
        AppThemeTokens.fallback;
  }

  static ThemeData light() => _buildTheme(Brightness.light);

  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF136F63),
      brightness: brightness,
    );
    final tokens =
        brightness == Brightness.light ? AppThemeTokens.light : AppThemeTokens.dark;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(
        color: colorScheme.outlineVariant.withOpacity(0.5),
      ),
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF4F7F5)
          : const Color(0xFF0E1412),
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.45),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? Colors.white.withOpacity(0.82)
            : colorScheme.surface.withOpacity(0.6),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: MaterialStatePropertyAll(
          TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }
}