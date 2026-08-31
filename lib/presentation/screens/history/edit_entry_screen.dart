import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/ledger_entry.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/receipt_picker_card.dart';

class EditEntryScreen extends ConsumerStatefulWidget {
  const EditEntryScreen({super.key, required this.entry});

  final LedgerEntry entry;

  @override
  ConsumerState<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends ConsumerState<EditEntryScreen> {
  late final TextEditingController _statementController;
  late final TextEditingController _noteController;
  late final TextEditingController _debitController;
  late final TextEditingController _creditController;
  late DateTime _selectedDate;
  File? _newReceiptImage;
  bool _removeReceiptImage = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _statementController = TextEditingController(text: entry.statement);
    _noteController = TextEditingController(text: entry.note ?? '');
    _debitController = TextEditingController(
      text: entry.debitAmount != null && entry.debitAmount! > 0 ? entry.debitAmount!.toString() : '',
    );
    _creditController = TextEditingController(
      text: entry.creditAmount != null && entry.creditAmount! > 0 ? entry.creditAmount!.toString() : '',
    );
    _selectedDate = DateTime.tryParse(entry.date) ?? DateTime.now();
  }

  @override
  void dispose() {
    _statementController.dispose();
    _noteController.dispose();
    _debitController.dispose();
    _creditController.dispose();
    super.dispose();
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

    final ok = await ref.read(ledgerProvider.notifier).updateEntry(
          original: widget.entry,
          entryDate: _selectedDate,
          statement: _statementController.text,
          note: _noteController.text,
          newReceiptImage: _newReceiptImage,
          removeReceiptImage: _removeReceiptImage,
          debitAmount: debit,
          creditAmount: credit,
        );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isSubmitting = ref.watch(ledgerProvider.select((s) => s.isSubmitting));

    ref.listen(ledgerProvider, (previous, next) {
      if (next.lastError != null && next.lastError != previous?.lastError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.lastError!), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('تعديل العملية رقم ${widget.entry.serial}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
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
          ),
          const SizedBox(height: 16),
          _FieldLabel('صورة الوصل'),
          ReceiptPickerCard(
            image: _newReceiptImage,
            existingRemoteUrl: _removeReceiptImage ? null : widget.entry.receiptUrl,
            onImagePicked: (f) => setState(() {
              _newReceiptImage = f;
              _removeReceiptImage = false;
            }),
            onImageRemoved: () => setState(() {
              _newReceiptImage = null;
              _removeReceiptImage = true;
            }),
          ),
          const SizedBox(height: 16),
          _FieldLabel('إضافة ملاحظة أو نص'),
          TextField(
            controller: _noteController,
            minLines: 1,
            maxLines: 3,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          _FieldLabel('مدين له'),
          AmountField(label: 'المبلغ', controller: _debitController, suffixText: settings.currency),
          const SizedBox(height: 16),
          _FieldLabel('مدين عليه'),
          AmountField(label: 'المبلغ', controller: _creditController, suffixText: settings.currency),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'حفظ التعديلات',
            icon: Icons.save_outlined,
            isLoading: isSubmitting,
            onPressed: _submit,
          ),
        ],
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
