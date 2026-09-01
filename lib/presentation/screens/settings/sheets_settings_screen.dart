import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/services/google_sheets_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';

class SheetsSettingsScreen extends ConsumerStatefulWidget {
  const SheetsSettingsScreen({super.key});

  @override
  ConsumerState<SheetsSettingsScreen> createState() =>
      _SheetsSettingsScreenState();
}

class _SheetsSettingsScreenState extends ConsumerState<SheetsSettingsScreen> {
  late final TextEditingController _spreadsheetIdController;
  late final TextEditingController _sheetNameController;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _spreadsheetIdController = TextEditingController(text: s.spreadsheetId);
    _sheetNameController = TextEditingController(text: s.sheetName);
  }

  @override
  void dispose() {
    _spreadsheetIdController.dispose();
    _sheetNameController.dispose();
    super.dispose();
  }

  Future<void> _persist() async {
    await ref.read(settingsProvider.notifier).update(
          (s) => s.copyWith(
            spreadsheetId: _spreadsheetIdController.text.trim(),
            sheetName: _sheetNameController.text.trim().isEmpty
                ? AppConstants.defaultSheetName
                : _sheetNameController.text.trim(),
          ),
        );
  }

  Future<void> _testConnection() async {
    FocusScope.of(context).unfocus();
    await _persist();

    if (!mounted) return;
    final account = ref.read(authProvider).account;
    final settings = ref.read(settingsProvider);
    if (account == null) {
      AppSnackbar.error(context, 'يرجى تسجيل الدخول أولاً.');
      return;
    }
    if (!settings.isSheetsConfigured) {
      AppSnackbar.error(context, 'يرجى إدخال Spreadsheet ID أولاً.');
      return;
    }

    setState(() => _testing = true);
    try {
      final client =
          await ref.read(googleAuthServiceProvider).getAuthorizedClient(account);
      try {
        final sheets = GoogleSheetsService(
          client: client,
          spreadsheetId: settings.spreadsheetId,
          sheetName: settings.sheetName,
          columnLetters: settings.effectiveColumnLetters,
        );
        await sheets.testConnection();
        if (mounted) {
          AppSnackbar.success(context, 'تم الاتصال بنجاح بـ Google Sheets');
        }
      } finally {
        client.close();
      }
    } on AppException catch (e) {
      if (mounted) AppSnackbar.error(context, e.message);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'تعذّر الاتصال بـ Google Sheets: $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSyncing = ref.watch(ledgerProvider.select((s) => s.isSyncing));

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('إعدادات Google Sheets')),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Spreadsheet ID',
                      controller: _spreadsheetIdController,
                      icon: Icons.tag_rounded,
                      hint: 'الجزء بين /d/ و /edit في رابط الشيت',
                      textDirection: TextDirection.ltr,
                      onChanged: (_) => _persist(),
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'اسم التبويب (Sheet / Tab)',
                      controller: _sheetNameController,
                      icon: Icons.tab_rounded,
                      hint: AppConstants.defaultSheetName,
                      textDirection: TextDirection.ltr,
                      onChanged: (_) => _persist(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'اختبار الاتصال',
                icon: Icons.wifi_tethering_rounded,
                isLoading: _testing,
                onPressed: _testConnection,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'مزامنة العمليات المعلّقة الآن',
                icon: Icons.sync_rounded,
                isLoading: isSyncing,
                onPressed: () async {
                  await _persist();
                  await ref.read(ledgerProvider.notifier).syncAll();
                },
              ),
              const SizedBox(height: 20),
              Text(
                'ترتيب الأعمدة قابل للتخصيص بالكامل من "تعديل الخلايا" في صفحة الإعدادات.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
