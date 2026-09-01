import 'package:flutter/material.dart';

/// Brand palette, derived from the MS logo: deep navy, cyan, electric blue
/// and a violet accent. Kept deliberately small - a financial app should
/// read as calm and premium, not colourful.
class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF0B1B3F);
  static const Color navyDeep = Color(0xFF060F26);
  static const Color blue = Color(0xFF2563EB);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color violet = Color(0xFF7C3AED);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Light surfaces
  static const Color lightBg = Color(0xFFF6F8FC);
  static const Color lightBgAlt = Color(0xFFEEF2FF);
  static const Color lightCard = Color(0xFFFFFFFF);

  // Dark surfaces
  static const Color darkBg = Color(0xFF080D1C);
  static const Color darkBgAlt = Color(0xFF0E1730);
  static const Color darkCard = Color(0xFF141E38);

  /// Brand gradient used for the primary button, logo marks and accents.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, blue, violet],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, blue],
  );

  /// Soft page background - avoids flat white, stays subtle.
  static LinearGradient pageGradient(Brightness brightness) {
    return brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkBgAlt, darkBg],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lightBgAlt, lightBg],
          );
  }

  /// Splash uses the full dark brand backdrop in both themes.
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1B3F), Color(0xFF060F26), Color(0xFF0B1B3F)],
  );

  static Color debitColor(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFFF8A8A) : danger;

  static Color creditColor(Brightness b) =>
      b == Brightness.dark ? const Color(0xFF5EE9B5) : success;
}
