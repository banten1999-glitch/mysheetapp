import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/ledger_entry.dart';
import '../../../domain/models/sync_status.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/sync_status_chip.dart';
import 'entry_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(ledgerProvider);
    final currency = ref.watch(settingsProvider).currency;

    ref.listen(ledgerProvider, (previous, next) {
      if (next.lastError != null && next.lastError != previous?.lastError) {
        AppSnackbar.error(context, next.lastError!);
      } else if (next.lastSuccessMessage != null &&
          next.lastSuccessMessage != previous?.lastSuccessMessage) {
        AppSnackbar.success(context, next.lastSuccessMessage!);
      }
    });

    final pending =
        state.entries.where((e) => e.syncStatus != SyncStatus.synced).length;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('سجل العمليات'),
          actions: [
            IconButton(
              tooltip: 'مزامنة الآن',
              icon: state.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(Icons.sync_rounded),
              onPressed: state.isSyncing
                  ? null
                  : () => ref.read(ledgerProvider.notifier).syncAll(),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => ref.read(ledgerProvider.notifier).refresh(),
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.entries.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 100),
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'لا توجد عمليات مسجلة بعد',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        children: [
                          if (pending > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _PendingBanner(count: pending),
                            ),
                          ...state.entries.map(
                            (entry) => _EntryTile(entry: entry, currency: currency),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.warning, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count عملية بانتظار المزامنة',
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.currency});

  final LedgerEntry entry;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDebit = entry.isDebit;
    final amountColor = isDebit
        ? AppColors.debitColor(theme.brightness)
        : AppColors.creditColor(theme.brightness);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: amountColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${entry.serial}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.statement,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(fontSize: 14.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Text(
                      entry.date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (entry.hasReceiptImage)
                      Icon(
                        Icons.image_rounded,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    const Spacer(),
                    SyncStatusChip(status: entry.syncStatus, compact: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isDebit ? '−' : '+'} ${AppFormatters.amount(entry.amount)}',
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currency,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
