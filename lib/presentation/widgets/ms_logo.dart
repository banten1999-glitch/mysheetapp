import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The app mark.
///
/// Uses `assets/images/logo.png` when it's present (the real MS artwork,
/// rendered untouched and aspect-preserved). Until that file is added, it
/// falls back to a drawn "MS" mark in the same brand colours so the app
/// still builds and looks finished.
class MsLogo extends StatelessWidget {
  const MsLogo({super.key, this.size = 120, this.onDarkBackground = false});

  final double size;
  final bool onDarkBackground;

  static const String assetPath = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) =>
            _FallbackMark(size: size, onDark: onDarkBackground),
      ),
    );
  }
}

/// Drawn stand-in: "MS" wordmark between code brackets, matching the real
/// logo's composition and palette closely enough to ship with.
class _FallbackMark extends StatelessWidget {
  const _FallbackMark({required this.size, required this.onDark});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bracketColor = AppColors.cyan.withValues(alpha: 0.85);
    final msColor = onDark ? Colors.white : AppColors.navy;

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '<',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                color: bracketColor,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            ShaderMask(
              shaderCallback: (bounds) => onDark
                  ? AppColors.blueGradient.createShader(bounds)
                  : LinearGradient(colors: [msColor, msColor]).createShader(bounds),
              child: const Text(
                'MS',
                style: TextStyle(
                  fontSize: 68,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -3,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '>',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                color: bracketColor,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
