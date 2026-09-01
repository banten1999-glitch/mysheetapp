import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Frosted surface used for every grouped block in the app. The blur is
/// deliberately light - enough to lift the card off the gradient without
/// looking heavy or costing frames.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.borderRadius = AppTheme.radiusLg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.055)
                  : Colors.white.withValues(alpha: 0.78),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.09)
                    : Colors.white.withValues(alpha: 0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.28)
                      : const Color(0xFF1E3A8A).withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card with a leading gradient icon and a title - the standard grouping
/// used across Settings and detail pages.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GradientIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Rounded square icon filled with the brand gradient.
class GradientIcon extends StatelessWidget {
  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 40,
    this.gradient,
  });

  final IconData icon;
  final double size;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22D3EE), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.52),
    );
  }
}
