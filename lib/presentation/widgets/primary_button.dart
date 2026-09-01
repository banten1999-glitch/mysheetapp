import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Gradient call-to-action with a subtle press-scale, a built-in loading
/// state, and taps disabled while loading (so a submit can't be fired twice).
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.gradient,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Gradient? gradient;
  final double height;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final radius = BorderRadius.circular(AppTheme.radiusMd);

    return AnimatedScale(
      scale: _pressed && enabled ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.6,
        duration: const Duration(milliseconds: 160),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.gradient ?? AppColors.blueGradient,
              borderRadius: radius,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.32),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: widget.isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        key: const ValueKey('label'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 20, color: Colors.white),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quieter secondary action, same press feedback and loading behaviour.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
  }
}
