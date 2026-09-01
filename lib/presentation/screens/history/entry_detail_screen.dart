import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/ledger_entry.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/sync_status_chip.dart';
import 'edit_entry_screen.dart';

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.entry});

  final LedgerEntry entry;

  Future<void> _openReceipt(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        AppSnackbar.error(context, 'تعذّر فتح رابط الصورة.');
      }
    }
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    LedgerEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.danger,
            size: 26,
          ),
        ),
        title: const Text('حذف العملية'),
        content: Text(
          'هل تريد حذف العملية رقم ${entry.serial} نهائياً؟\nلا يمكن التراجع عن هذا الإجراء.',
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'حذف',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref.read(ledgerProvider.notifier).deleteEntry(entry);
    if (ok && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(settingsProvider).currency;

    // Prefer the live copy from the list (reflects edits/sync updates);
    // fall back to the entry passed in if it's no longer in the list.
    final entries = ref.watch(ledgerProvider.select((s) => s.entries));
    final entry = entries.firstWhere(
      (e) => e.transactionId == this.entry.transactionId,
      orElse: () => this.entry,
    );

    final isDebit = entry.isDebit;
    final amountColor = isDebit
        ? AppColors.debitColor(theme.brightness)
        : AppColors.creditColor(theme.brightness);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('عملية #${entry.serial}'),
          actions: [
            IconButton(
              tooltip: 'تعديل',
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditEntryScreen(entry: entry)),
              ),
            ),
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.danger,
              onPressed: () => _confirmAndDelete(context, ref, entry),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              // Amount hero
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      isDebit ? 'مدين له (مدفوع)' : 'مدين عليه (مستلم)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          AppFormatters.amount(entry.amount),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currency,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SyncStatusChip(status: entry.syncStatus),
                    if (entry.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        entry.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Column(
                  children: [
                    _DetailRow(label: 'البيان', value: entry.statement),
                    const Divider(height: 1),
                    _DetailRow(label: 'التاريخ', value: entry.date),
                    if (entry.note != null) ...[
                      const Divider(height: 1),
                      _DetailRow(label: 'ملاحظة', value: entry.note!),
                    ],
                    const Divider(height: 1),
                    _DetailRow(
                      label: 'معرف العملية',
                      value: entry.transactionId,
                      monospace: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const GradientIcon(
                          icon: Icons.receipt_long_rounded,
                          size: 34,
                          gradient: LinearGradient(
                            colors: [AppColors.violet, AppColors.blue],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('صورة الوصل', style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (entry.localImagePath != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: Image.file(File(entry.localImagePath!)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'بانتظار الرفع إلى Google Drive',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ] else if (entry.receiptUrl != null)
                      SecondaryButton(
                        label: 'فتح صورة الوصل',
                        icon: Icons.open_in_new_rounded,
                        onPressed: () => _openReceipt(context, entry.receiptUrl!),
                      )
                    else
                      Text(
                        'لا توجد صورة وصل لهذه العملية.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: monospace
                  ? theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
