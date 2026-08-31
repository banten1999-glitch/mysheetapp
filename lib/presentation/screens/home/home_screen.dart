import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/receipt_picker_card.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _statementController = TextEditingController();
  final _noteController = TextEditingController();
  final _debitController = TextEditingController();
  final _creditController = TextEditingController();
  final _serialController = TextEditingController();
  File? _receiptImage;
  int? _lastSyncedSerial;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _statementController.dispose();
    _noteController.dispose();
    _debitController.dispose();
    _creditController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _statementController.clear();
    _noteController.clear();
    _debitController.clear();
    _creditController.clear();
    setState(() {
      _receiptImage = null;
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final debit = _debitController.text.trim().isEmpty
        ? null
        : double.tryParse(_debitController.text.trim());
    final credit = _creditController.text.trim().isEmpty
        ? null
        : double.tryParse(_creditController.text.trim());

    final ok = await ref.read(ledgerProvider.notifier).addEntry(
          entryDate: _selectedDate,
          statement: _statementController.text,
          note: _noteController.text,
          receiptImage: _receiptImage,
          debitAmount: debit,
          creditAmount: credit,
        );
    if (ok) _resetForm();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final ledgerState = ref.watch(ledgerProvider);
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    if (_lastSyncedSerial != ledgerState.nextSerial) {
      _lastSyncedSerial = ledgerState.nextSerial;
      _serialController.text = ledgerState.nextSerial.toString();
    }

    ref.listen(ledgerProvider, (previous, next) {
      if (next.lastError != null && next.lastError != previous?.lastError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.lastError!), backgroundColor: Theme.of(context).colorScheme.error),
        );
      } else if (next.lastSuccessMessage != null &&
          next.lastSuccessMessage != previous?.lastSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.lastSuccessMessage!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.appName),
        actions: [
          IconButton(
            tooltip: 'سجل العمليات',
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(ledgerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (!isOnline) const _StatusBanner(
              icon: Icons.cloud_off,
              text: 'أنت غير متصل بالإنترنت. سيتم حفظ العمليات محلياً ومزامنتها لاحقاً.',
              color: Colors.orange,
            ),
            if (!settings.isFullyConfigured)
              const _StatusBanner(
                icon: Icons.settings_suggest_outlined,
                text: 'يرجى إكمال إعداد Google Sheets وGoogle Drive من صفحة الإعدادات.',
                color: Colors.blueGrey,
              ),
            const SizedBox(height: 4),
            _FieldLabel('رقم الرديف'),
            if (settings.manualSerialEditable)
              TextField(
                controller: _serialController,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null) ref.read(ledgerProvider.notifier).setManualSerial(n);
                },
                decoration: const InputDecoration(prefixIcon: Icon(Icons.tag)),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tag),
                    const SizedBox(width: 10),
                    Text(
                      ledgerState.nextSerial.toString(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _FieldLabel('التاريخ'),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today_outlined)),
                child: Text(AppFormatters.date(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel('البيان'),
            TextField(
              controller: _statementController,
              minLines: 2,
              maxLines: 4,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(hintText: 'مثال: دفع إيجار، شراء بضاعة...'),
            ),
            const SizedBox(height: 16),
            _FieldLabel('صورة الوصل'),
            ReceiptPickerCard(
              image: _receiptImage,
              onImagePicked: (f) => setState(() => _receiptImage = f),
              onImageRemoved: () => setState(() => _receiptImage = null),
            ),
            const SizedBox(height: 16),
            _FieldLabel('إضافة ملاحظة أو نص'),
            TextField(
              controller: _noteController,
              minLines: 1,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(hintText: 'مثال: تم الدفع نقداً ولا يوجد وصل.'),
            ),
            const SizedBox(height: 16),
            _FieldLabel('مدين له'),
            AmountField(label: 'المبلغ', controller: _debitController, suffixText: settings.currency),
            const SizedBox(height: 16),
            _FieldLabel('مدين عليه'),
            AmountField(label: 'المبلغ', controller: _creditController, suffixText: settings.currency),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'رفع وحفظ العملية',
              icon: Icons.cloud_upload_outlined,
              isLoading: ledgerState.isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}
