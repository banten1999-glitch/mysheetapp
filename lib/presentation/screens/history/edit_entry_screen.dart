import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/ledger_entry.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_card.dart';
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
      text: entry.debitAmount != null && entry.debitAmount! > 0
          ? entry.debitAmount!.toString()
          : '',
    );
    _creditController = TextEditingController(
      text: entry.creditAmount != null && entry.creditAmount! > 0
          ? entry.creditAmount!.toString()
          : '',
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
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final isSubmitting = ref.watch(ledgerProvider.select((s) => s.isSubmitting));

    ref.listen(ledgerProvider, (previous, next) {
      if (next.lastError != null && next.lastError != previous?.lastError) {
        AppSnackbar.error(context, next.lastError!);
      }
    });

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text('تعديل العملية #${widget.entry.serial}')),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTapField(
                      label: 'التاريخ',
                      value: AppFormatters.date(_selectedDate),
                      icon: Icons.calendar_today_rounded,
                      onTap: _pickDate,
                      trailing: Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'البيان',
                      controller: _statementController,
                      icon: Icons.description_rounded,
                      minLines: 2,
                      maxLines: 4,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AmountField(
                      label: 'مدين له (مدفوع)',
                      controller: _debitController,
                      suffixText: settings.currency,
                      accentColor: AppColors.debitColor(theme.brightness),
                      icon: Icons.arrow_upward_rounded,
                    ),
                    const SizedBox(height: 16),
                    AmountField(
                      label: 'مدين عليه (مستلم)',
                      controller: _creditController,
                      suffixText: settings.currency,
                      accentColor: AppColors.creditColor(theme.brightness),
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReceiptPickerCard(
                      image: _newReceiptImage,
                      existingRemoteUrl:
                          _removeReceiptImage ? null : widget.entry.receiptUrl,
                      onImagePicked: (f) => setState(() {
                        _newReceiptImage = f;
                        _removeReceiptImage = false;
                      }),
                      onImageRemoved: () => setState(() {
                        _newReceiptImage = null;
                        _removeReceiptImage = true;
                      }),
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'ملاحظة أو نص بديل',
                      controller: _noteController,
                      icon: Icons.sticky_note_2_rounded,
                      minLines: 1,
                      maxLines: 3,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              PrimaryButton(
                label: 'حفظ التعديلات',
                icon: Icons.save_rounded,
                isLoading: isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
