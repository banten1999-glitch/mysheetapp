import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/ledger_entry.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/sync_status_chip.dart';
import 'entry_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ledgerProvider);
    final currency = ref.watch(settingsProvider).currency;

    ref.listen(ledgerProvider, (previous, next) {
      if (next.lastError != null && next.lastError != previous?.lastError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.lastError!), backgroundColor: Theme.of(context).colorScheme.error),
        );
      } else if (next.lastSuccessMessage != null &&
          next.lastSuccessMessage != previous?.lastSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.lastSuccessMessage!)));
      }
    });

    return Scaffold(
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
                : const Icon(Icons.sync),
            onPressed: state.isSyncing ? null : () => ref.read(ledgerProvider.notifier).syncAll(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(ledgerProvider.notifier).refresh(),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.entries.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('لا توجد عمليات مسجلة بعد.')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = state.entries[index];
                      return _EntryTile(entry: entry, currency: currency);
                    },
                  ),
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
    final amountColor = entry.isDebit ? Colors.red : Colors.green;
    final amountPrefix = entry.isDebit ? '- ' : '+ ';

    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry)),
        ),
        leading: CircleAvatar(child: Text('${entry.serial}')),
        title: Text(entry.statement, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(AppFormatters.displayDateTime(entry.createdAt),
                  style: Theme.of(context).textTheme.bodySmall),
              SyncStatusChip(status: entry.syncStatus),
            ],
          ),
        ),
        trailing: Text(
          '$amountPrefix${AppFormatters.amountWithCurrency(entry.amount, currency)}',
          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
