import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Soft branded page backdrop: a vertical gradient plus two very faint
/// colour blooms, so pages never read as flat white.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.pageGradient(brightness)),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -100,
            child: _Bloom(
              color: AppColors.cyan.withValues(alpha: isDark ? 0.16 : 0.20),
              size: 320,
            ),
          ),
          Positioned(
            bottom: -160,
            left: -120,
            child: _Bloom(
              color: AppColors.violet.withValues(alpha: isDark ? 0.14 : 0.14),
              size: 340,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Bloom extends StatelessWidget {
  const _Bloom({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
