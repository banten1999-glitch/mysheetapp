import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'glass_card.dart';

/// Navigation row used on the Settings hub: gradient icon, title, optional
/// status line, and a chevron. Presses give a small scale response.
class SettingsTile extends StatefulWidget {
  const SettingsTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.gradient,
    this.trailing,
    this.statusOk,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Widget? trailing;

  /// When set, shows a small dot: green when configured, amber when not.
  final bool? statusOk;

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: widget.onTap,
          child: Row(
            children: [
              GradientIcon(icon: widget.icon, gradient: widget.gradient),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                        if (widget.statusOk != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.statusOk!
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              widget.trailing ??
                  Icon(
                    Icons.chevron_left_rounded,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
