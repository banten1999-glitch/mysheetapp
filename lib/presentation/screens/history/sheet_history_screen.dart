import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/services/google_sheets_service.dart';
import '../../../domain/models/app_settings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/settings_provider.dart';
import 'edit_entry_screen.dart';

/// Online view of the actual sheet, independent of the device's local history.
class SheetHistoryScreen extends ConsumerStatefulWidget {
  const SheetHistoryScreen({super.key});

  @override
  ConsumerState<SheetHistoryScreen> createState() => _SheetHistoryScreenState();
}

class _SheetHistoryScreenState extends ConsumerState<SheetHistoryScreen> {
  List<SheetLedgerRow> _rows = [];
  bool _loading = false;
  bool _opening = false;
  String? _error;
  String _query = '';
  AppSettings? _loadedSettings;
  String? _loadedAccount;

  Future<T> _withSheet<T>(
    Future<T> Function(GoogleSheetsService) action,
  ) async {
    final settings = ref.read(settingsProvider);
    final account = ref.read(authProvider).account;
    if (account == null) throw const AuthException('يرجى تسجيل الدخول أولاً.');
    if (!settings.isSheetsConfigured) {
      throw const SettingsNotConfiguredException(
        'أكمل إعداد Google Sheets أولاً.',
      );
    }
    final client = await ref
        .read(googleAuthServiceProvider)
        .getAuthorizedClient(account);
    try {
      return await action(
        GoogleSheetsService(
          client: client,
          spreadsheetId: settings.spreadsheetId,
          sheetName: settings.sheetName,
          columnLetters: settings.effectiveColumnLetters,
        ),
      );
    } finally {
      client.close();
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final settings = ref.read(settingsProvider);
    final account = ref.read(authProvider).account;
    try {
      final rows = await _withSheet((sheet) => sheet.fetchEntries());
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loadedSettings = settings;
        _loadedAccount = account?.id;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذّر جلب العمليات: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(SheetLedgerRow row) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await _editRow(row);
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذّر فتح العملية: $e');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _editRow(SheetLedgerRow row) async {
    if (!identical(ref.read(settingsProvider), _loadedSettings) ||
        ref.read(authProvider).account?.id != _loadedAccount) {
      setState(() => _error = 'تغير الحساب أو الإعدادات. حدّث القائمة أولاً.');
      return;
    }
    // Entries created on this device must keep using its existing offline
    // queue, otherwise a later local retry could overwrite the remote edit.
    final local = await ref.read(ledgerRepositoryProvider).getAll();
    if (!mounted) return;
    for (final entry in local) {
      if (row.text('transactionId').isNotEmpty &&
          entry.transactionId == row.text('transactionId')) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EditEntryScreen(entry: entry)),
        );
        if (mounted) await _load();
        return;
      }
    }
    final entry = await _withSheet((sheet) => sheet.entryForEditing(row));
    if (!mounted) return;
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => EditEntryScreen(entry: entry, onSave: (values) async {
        final settings = ref.read(settingsProvider);
        final account = ref.read(authProvider).account;
        if (!identical(settings, _loadedSettings) || account?.id != _loadedAccount) {
          throw const SheetsException('تغير الحساب أو الإعدادات. حدّث القائمة أولاً.');
        }
        await ref.read(ledgerRepositoryProvider).updateSheetEntry(
          snapshot: row, original: entry, entryDate: values.date,
          statement: values.statement, note: values.note,
          debitAmount: values.debit, creditAmount: values.credit,
          newReceiptImage: values.image, removeReceiptImage: values.removeImage,
          settings: settings, account: account,
        );
      }),
    ));
    if (!mounted) return;
    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تعديل الرديف ${row.serial} في Google Sheets.')),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = SheetLedgerRow.parseSerial(_query);
    final visible = _rows
        .where((row) => _query.trim().isEmpty || row.serial == query)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('عمليات Google Sheets')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'العمليات بعد الرديف 150 (من 151 فما فوق)، بما فيها العمليات المضافة يدوياً. التعديل يتطلب اتصالاً بالإنترنت.',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('جلب / تحديث عمليات الشيت'),
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'ابحث برقم الرديف',
                    hintText: 'مثلاً 151 — اتركه فارغاً لعرض الكل',
                    prefixIcon: const Icon(Icons.search),
                    errorText: _query.trim().isNotEmpty && query == null
                        ? 'أدخل رقم رديف صحيحاً'
                        : null,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (visible.isEmpty && !_loading)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _loadedSettings == null
                            ? 'اضغط جلب عمليات الشيت لعرض العمليات.'
                            : 'لا توجد عمليات مطابقة بعد الرديف 150.',
                      ),
                    ),
                  ...visible.map(
                    (row) => ListTile(
                      title: Text('#${row.serial} — ${row.text('statement')}'),
                      subtitle: Text(
                        '${row.text('date')}\nمدين له: ${row.text('debit')}   مدين عليه: ${row.text('credit')}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: _loading || _opening ? null : () => _edit(row),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
