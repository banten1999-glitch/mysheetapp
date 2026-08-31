import 'package:flutter/material.dart';

import '../../domain/models/sync_status.dart';

class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      SyncStatus.pending => (Colors.orange, Icons.schedule),
      SyncStatus.syncing => (Colors.blue, Icons.sync),
      SyncStatus.synced => (Colors.green, Icons.check_circle),
      SyncStatus.failed => (Colors.red, Icons.error_outline),
    };
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(status.label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
