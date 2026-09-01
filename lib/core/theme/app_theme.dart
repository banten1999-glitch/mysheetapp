import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Material 3 themes tuned to feel close to modern iOS: generous radii,
/// soft surfaces, restrained shadows, and clear typographic hierarchy.
class AppTheme {
  AppTheme._();

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 22;
  static const double radiusXl = 28;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? AppColors.cyan : AppColors.blue,
          secondary: AppColors.violet,
          tertiary: AppColors.cyan,
          surface: isDark ? AppColors.darkBg : AppColors.lightBg,
          surfaceContainerLowest: isDark ? AppColors.darkBg : AppColors.lightBg,
          surfaceContainer: isDark ? AppColors.darkCard : AppColors.lightCard,
          surfaceContainerHigh: isDark ? AppColors.darkCard : AppColors.lightCard,
          error: AppColors.danger,
        );

    final baseText = isDark
        ? Typography.whiteMountainView
        : Typography.blackMountainView;

    final textTheme = baseText.copyWith(
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: baseText.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(height: 1.35),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      // Pages paint their own gradient via AppBackground.
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 19),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.9),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
          fontSize: 14,
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        floatingLabelStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFEDF1F7),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : Colors.white.withValues(alpha: 0.86),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : const Color(0xFFE7EDF6),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: scheme.primary,
          foregroundColor: isDark ? AppColors.navyDeep : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFEDF1F7),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF1F5F9),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 18),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : (isDark ? const Color(0xFF9AA6C0) : Colors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFD8E0EC)),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.15),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
