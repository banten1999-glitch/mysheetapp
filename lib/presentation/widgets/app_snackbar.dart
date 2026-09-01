import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

enum AppMessageType { success, error, info }

/// Floating toast used for every success/error message in the app, in place
/// of the default grey SnackBar.
class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    AppMessageType type = AppMessageType.info,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final (color, icon) = switch (type) {
      AppMessageType.success => (AppColors.success, Icons.check_circle_rounded),
      AppMessageType.error => (AppColors.danger, Icons.error_rounded),
      AppMessageType.info => (AppColors.blue, Icons.info_rounded),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: Duration(seconds: type == AppMessageType.error ? 5 : 3),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: _ToastBody(message: message, color: color, icon: icon),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: AppMessageType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: AppMessageType.error);
}

class _ToastBody extends StatelessWidget {
  const _ToastBody({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17223D) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
