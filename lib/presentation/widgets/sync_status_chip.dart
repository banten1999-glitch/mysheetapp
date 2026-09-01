import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models/sync_status.dart';

class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key, required this.status, this.compact = false});

  final SyncStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      SyncStatus.pending => (AppColors.warning, Icons.schedule_rounded),
      SyncStatus.syncing => (AppColors.blue, Icons.sync_rounded),
      SyncStatus.synced => (AppColors.success, Icons.check_circle_rounded),
      SyncStatus.failed => (AppColors.danger, Icons.error_rounded),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 2.5 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10.5 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
