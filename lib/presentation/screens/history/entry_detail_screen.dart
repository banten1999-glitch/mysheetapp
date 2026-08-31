import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/ledger_entry.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/sync_status_chip.dart';
import 'edit_entry_screen.dart';

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.entry});

  final LedgerEntry entry;

  Future<void> _openReceipt(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح رابط الصورة.')),
        );
      }
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref, LedgerEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف العملية'),
        content: Text('هل تريد حذف العملية رقم ${entry.serial} نهائياً؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('حذف', style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
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
    final currency = ref.watch(settingsProvider).currency;
    // Prefer the live copy from the list (reflects edits/sync updates);
    // fall back to the entry passed in if it's no longer in the list.
    final entries = ref.watch(ledgerProvider.select((s) => s.entries));
    final entry = entries.firstWhere(
      (e) => e.transactionId == this.entry.transactionId,
      orElse: () => this.entry,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل العملية رقم ${entry.serial}'),
        actions: [
          IconButton(
            tooltip: 'تعديل',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EditEntryScreen(entry: entry)),
            ),
          ),
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmAndDelete(context, ref, entry),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('رديف: ${entry.serial}', style: Theme.of(context).textTheme.titleMedium),
              SyncStatusChip(status: entry.syncStatus),
            ],
          ),
          if (entry.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(entry.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          _DetailRow('البيان', entry.statement),
          _DetailRow('التاريخ', entry.date),
          _DetailRow('الوقت', entry.time),
          _DetailRow(
            entry.isDebit ? 'مدين له' : 'مدين عليه',
            AppFormatters.amountWithCurrency(entry.amount, currency),
          ),
          if (entry.note != null) _DetailRow('ملاحظة', entry.note!),
          _DetailRow('معرف العملية', entry.transactionId),
          const SizedBox(height: 20),
          if (entry.localImagePath != null) ...[
            Text('صورة الوصل (بانتظار الرفع)', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(entry.localImagePath!)),
            ),
          ] else if (entry.receiptUrl != null) ...[
            Text('صورة الوصل', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openReceipt(context, entry.receiptUrl!),
              icon: const Icon(Icons.open_in_new),
              label: const Text('فتح صورة الوصل'),
            ),
          ] else
            Text('لا توجد صورة وصل لهذه العملية.', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: SelectableText(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
