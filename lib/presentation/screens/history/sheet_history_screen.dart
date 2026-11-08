import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/services/google_sheets_service.dart';
import '../../../domain/models/app_settings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/settings_provider.dart';
import 'entry_detail_screen.dart';

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
          MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry)),
        );
        if (mounted) await _load();
        return;
      }
    }
    final changes = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => _SheetEditDialog(
        row: row,
        allowBoth: ref.read(settingsProvider).allowBothAmounts,
      ),
    );
    if (changes == null || changes.isEmpty || !mounted) return;
    final settings = ref.read(settingsProvider);
    if (!identical(settings, _loadedSettings) ||
        ref.read(authProvider).account?.id != _loadedAccount) {
      setState(() => _error = 'تغير الحساب أو الإعدادات. حدّث القائمة أولاً.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _withSheet((sheet) => sheet.updateEntryBySerial(row, changes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تعديل الرديف ${row.serial} في Google Sheets.'),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'لم يتم حفظ التعديل: $e');
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    await _load();
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

class _SheetEditDialog extends StatefulWidget {
  const _SheetEditDialog({required this.row, required this.allowBoth});
  final SheetLedgerRow row;
  final bool allowBoth;

  @override
  State<_SheetEditDialog> createState() => _SheetEditDialogState();
}

class _SheetEditDialogState extends State<_SheetEditDialog> {
  static const labels = {
    'date': 'التاريخ',
    'statement': 'البيان',
    'note': 'الملاحظة',
    'debit': 'مدين له',
    'credit': 'مدين عليه',
  };
  late final controllers = {
    for (final field in labels.keys)
      field: TextEditingController(text: widget.row.text(field)),
  };
  String? error;

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void save() {
    final changes = <String, Object?>{};
    for (final field in labels.keys) {
      final value = controllers[field]!.text;
      if (value == widget.row.text(field)) continue;
      if (field == 'debit' || field == 'credit') {
        final normalized = SheetLedgerRow.normalizeDigits(value)
            .replaceAll(',', '')
            .replaceAll('٬', '')
            .replaceAll('٫', '.');
        final number = double.tryParse(normalized);
        if (value.trim().isNotEmpty &&
            (number == null || !number.isFinite || number < 0)) {
          setState(() => error = 'أدخل مبلغاً صحيحاً غير سالب.');
          return;
        }
        changes[field] = number ?? '';
      } else {
        if ((field == 'statement' || field == 'date') && value.trim().isEmpty) {
          setState(() => error = 'التاريخ والبيان مطلوبان.');
          return;
        }
        changes[field] = value.trim();
      }
    }
    if (changes.containsKey('debit') || changes.containsKey('credit')) {
      double? amount(String field) => double.tryParse(
        SheetLedgerRow.normalizeDigits(
          (changes[field] ?? widget.row.text(field)).toString(),
        ).replaceAll(',', '').replaceAll('٬', '').replaceAll('٫', '.'),
      );
      final debit = amount('debit');
      final credit = amount('credit');
      // Unknown formula values are retained and not treated as zero.
      if (debit != null &&
          credit != null &&
          debit > 0 &&
          credit > 0 &&
          !widget.allowBoth) {
        setState(() => error = 'لا يمكن إدخال المبلغين معاً حسب الإعدادات.');
        return;
      }
      if ((debit ?? 0) <= 0 &&
          (credit ?? 0) <= 0 &&
          !controllers['debit']!.text.startsWith('=') &&
          !controllers['credit']!.text.startsWith('=')) {
        setState(() => error = 'أدخل مبلغاً أكبر من صفر في أحد الحقلين.');
        return;
      }
    }
    Navigator.of(context).pop(changes);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('تعديل الرديف ${widget.row.serial}'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final field in labels.keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[field],
                  readOnly: widget.row.text(field).startsWith('='),
                  decoration: InputDecoration(
                    labelText: labels[field],
                    helperText: widget.row.text(field).startsWith('=')
                        ? 'معادلة محفوظة — عدّلها من الشيت'
                        : null,
                  ),
                ),
              ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('إلغاء'),
      ),
      FilledButton(onPressed: save, child: const Text('حفظ في الشيت')),
    ],
  );
}
