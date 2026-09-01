import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/ms_logo.dart';
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

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final ledgerState = ref.watch(ledgerProvider);
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    if (_lastSyncedSerial != ledgerState.nextSerial) {
      _lastSyncedSerial = ledgerState.nextSerial;
      _serialController.text = ledgerState.nextSerial.toString();
    }

    ref.listen(ledgerProvider, (previous, next) {
      if (next.lastError != null && next.lastError != previous?.lastError) {
        AppSnackbar.error(context, next.lastError!);
      } else if (next.lastSuccessMessage != null &&
          next.lastSuccessMessage != previous?.lastSuccessMessage) {
        AppSnackbar.success(context, next.lastSuccessMessage!);
      }
    });

    final pendingCount = ledgerState.entries
        .where((e) => e.syncStatus.name != 'synced')
        .length;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => ref.read(ledgerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
              children: [
                _Header(
                  appName: settings.appName,
                  onHistory: () => _open(const HistoryScreen()),
                  onSettings: () => _open(const SettingsScreen()),
                  pendingCount: pendingCount,
                ),
                const SizedBox(height: 18),
                if (!isOnline)
                  const _Banner(
                    icon: Icons.cloud_off_rounded,
                    text: 'غير متصل بالإنترنت — تُحفظ العمليات محلياً وتُزامَن لاحقاً.',
                    color: AppColors.warning,
                  ),
                if (!settings.isFullyConfigured)
                  _Banner(
                    icon: Icons.settings_suggest_rounded,
                    text: 'أكمل ربط Google Sheets وDrive من الإعدادات.',
                    color: AppColors.blue,
                    onTap: () => _open(const SettingsScreen()),
                  ),

                // ── Balance ────────────────────────────────────────────
                const BalanceCard(),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const GradientIcon(
                      icon: Icons.add_circle_outline_rounded,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Text('إضافة عملية جديدة', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Operation details ──────────────────────────────────
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SerialField(
                              editable: settings.manualSerialEditable,
                              controller: _serialController,
                              serial: ledgerState.nextSerial,
                              onChanged: (v) {
                                final n = int.tryParse(v);
                                if (n != null) {
                                  ref
                                      .read(ledgerProvider.notifier)
                                      .setManualSerial(n);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTapField(
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        label: 'البيان',
                        controller: _statementController,
                        icon: Icons.description_rounded,
                        hint: 'مثال: دفع إيجار، شراء بضاعة...',
                        minLines: 2,
                        maxLines: 4,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Amounts ────────────────────────────────────────────
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const GradientIcon(
                            icon: Icons.account_balance_wallet_rounded,
                            size: 34,
                          ),
                          const SizedBox(width: 10),
                          Text('المبلغ', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
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

                // ── Receipt + note ─────────────────────────────────────
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
                          Text('الوصل', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ReceiptPickerCard(
                        image: _receiptImage,
                        onImagePicked: (f) => setState(() => _receiptImage = f),
                        onImageRemoved: () => setState(() => _receiptImage = null),
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        label: 'ملاحظة أو نص بديل',
                        controller: _noteController,
                        icon: Icons.sticky_note_2_rounded,
                        hint: 'مثال: تم الدفع نقداً ولا يوجد وصل.',
                        minLines: 1,
                        maxLines: 3,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                PrimaryButton(
                  label: 'رفع وحفظ العملية',
                  icon: Icons.cloud_upload_rounded,
                  isLoading: ledgerState.isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Greeting row with the logo and quick access to history / settings.
class _Header extends StatelessWidget {
  const _Header({
    required this.appName,
    required this.onHistory,
    required this.onSettings,
    required this.pendingCount,
  });

  final String appName;
  final VoidCallback onHistory;
  final VoidCallback onSettings;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const MsLogo(size: 34),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'عملية جديدة',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 19),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                appName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _CircleAction(
          icon: Icons.receipt_long_rounded,
          tooltip: 'سجل العمليات',
          onTap: onHistory,
          badgeCount: pendingCount,
        ),
        const SizedBox(width: 8),
        _CircleAction(
          icon: Icons.settings_rounded,
          tooltip: 'الإعدادات',
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE7EDF6),
              ),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, size: 21, color: theme.colorScheme.primary),
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -3,
              left: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                ),
                child: Text(
                  '$badgeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Read-only serial display, or an editable field when the setting allows.
class _SerialField extends StatelessWidget {
  const _SerialField({
    required this.editable,
    required this.controller,
    required this.serial,
    required this.onChanged,
  });

  final bool editable;
  final TextEditingController controller;
  final int serial;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (editable) {
      return AppTextField(
        label: 'الرديف',
        controller: controller,
        icon: Icons.tag_rounded,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
      );
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, left: 4, bottom: 7),
          child: Text(
            'الرديف',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13.5,
            ),
          ),
        ),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.14 : 0.08,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.tag_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                '$serial',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_left_rounded, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
