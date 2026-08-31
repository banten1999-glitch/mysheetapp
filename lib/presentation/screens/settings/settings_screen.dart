import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/services/google_drive_service.dart';
import '../../../data/services/google_sheets_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/primary_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _spreadsheetIdController;
  late final TextEditingController _sheetNameController;
  late final TextEditingController _driveFolderIdController;
  late final TextEditingController _startingSerialController;
  late final TextEditingController _appNameController;

  bool _testingSheets = false;
  bool _testingDrive = false;
  bool _creatingFolder = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _spreadsheetIdController = TextEditingController(text: s.spreadsheetId);
    _sheetNameController = TextEditingController(text: s.sheetName);
    _driveFolderIdController = TextEditingController(text: s.driveFolderId);
    _startingSerialController = TextEditingController(text: s.startingSerial.toString());
    _appNameController = TextEditingController(text: s.appName);
  }

  @override
  void dispose() {
    _spreadsheetIdController.dispose();
    _sheetNameController.dispose();
    _driveFolderIdController.dispose();
    _startingSerialController.dispose();
    _appNameController.dispose();
    super.dispose();
  }

  void _persistTextFields() {
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(
          spreadsheetId: _spreadsheetIdController.text.trim(),
          sheetName: _sheetNameController.text.trim().isEmpty
              ? 'Sheet1'
              : _sheetNameController.text.trim(),
          driveFolderId: _driveFolderIdController.text.trim(),
          startingSerial: int.tryParse(_startingSerialController.text.trim()) ?? s.startingSerial,
          appName: _appNameController.text.trim().isEmpty ? s.appName : _appNameController.text.trim(),
        ));
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _testSheetsConnection() async {
    _persistTextFields();
    final account = ref.read(authProvider).account;
    final settings = ref.read(settingsProvider);
    if (account == null) {
      _showMessage('يرجى تسجيل الدخول أولاً.', isError: true);
      return;
    }
    if (!settings.isSheetsConfigured) {
      _showMessage('يرجى إدخال Spreadsheet ID أولاً.', isError: true);
      return;
    }
    setState(() => _testingSheets = true);
    try {
      final client = await ref.read(googleAuthServiceProvider).getAuthorizedClient(account);
      try {
        final sheets = GoogleSheetsService(
          client: client,
          spreadsheetId: settings.spreadsheetId,
          sheetName: settings.sheetName,
        );
        await sheets.testConnection();
        _showMessage('تم الاتصال بنجاح بـ Google Sheets');
      } finally {
        client.close();
      }
    } on AppException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (e) {
      _showMessage('تعذّر الاتصال بـ Google Sheets: $e', isError: true);
    } finally {
      if (mounted) setState(() => _testingSheets = false);
    }
  }

  Future<void> _testDriveConnection() async {
    _persistTextFields();
    final account = ref.read(authProvider).account;
    final settings = ref.read(settingsProvider);
    if (account == null) {
      _showMessage('يرجى تسجيل الدخول أولاً.', isError: true);
      return;
    }
    if (!settings.isDriveConfigured) {
      _showMessage('يرجى إدخال Folder ID أولاً.', isError: true);
      return;
    }
    setState(() => _testingDrive = true);
    try {
      final client = await ref.read(googleAuthServiceProvider).getAuthorizedClient(account);
      try {
        final drive = GoogleDriveService(client: client);
        await drive.testConnection(settings.driveFolderId);
        _showMessage('تم الاتصال بنجاح بـ Google Drive');
      } finally {
        client.close();
      }
    } on AppException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (e) {
      _showMessage('تعذّر الاتصال بـ Google Drive: $e', isError: true);
    } finally {
      if (mounted) setState(() => _testingDrive = false);
    }
  }

  Future<void> _createFolder() async {
    final account = ref.read(authProvider).account;
    if (account == null) {
      _showMessage('يرجى تسجيل الدخول أولاً.', isError: true);
      return;
    }
    setState(() => _creatingFolder = true);
    try {
      final client = await ref.read(googleAuthServiceProvider).getAuthorizedClient(account);
      try {
        final drive = GoogleDriveService(client: client);
        final name = ref.read(settingsProvider).appName;
        final id = await drive.createFolder('وصولات $name');
        setState(() => _driveFolderIdController.text = id);
        _persistTextFields();
        _showMessage('تم إنشاء مجلد جديد وربطه بالتطبيق.');
      } finally {
        client.close();
      }
    } on AppException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (e) {
      _showMessage('تعذّر إنشاء المجلد: $e', isError: true);
    } finally {
      if (mounted) setState(() => _creatingFolder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'الحساب',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(auth.account?.displayName ?? auth.account?.email ?? 'غير مسجل الدخول'),
                subtitle: auth.account?.email != null ? Text(auth.account!.email) : null,
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                },
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج'),
              ),
            ],
          ),
          _SectionCard(
            title: 'إعدادات Google Sheets',
            children: [
              TextField(
                controller: _spreadsheetIdController,
                onEditingComplete: _persistTextFields,
                decoration: const InputDecoration(labelText: 'Spreadsheet ID'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sheetNameController,
                onEditingComplete: _persistTextFields,
                decoration: const InputDecoration(labelText: 'اسم Sheet / Tab'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'اختبار الاتصال',
                      icon: Icons.wifi_tethering,
                      isLoading: _testingSheets,
                      onPressed: _testSheetsConnection,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _persistTextFields();
                        ref.read(ledgerProvider.notifier).syncAll();
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('مزامنة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          _SectionCard(
            title: 'إعدادات Google Drive',
            children: [
              TextField(
                controller: _driveFolderIdController,
                onEditingComplete: _persistTextFields,
                decoration: const InputDecoration(labelText: 'Drive Folder ID'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'اختبار الاتصال',
                      icon: Icons.wifi_tethering,
                      isLoading: _testingDrive,
                      onPressed: _testDriveConnection,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _creatingFolder ? null : _createFolder,
                      icon: _creatingFolder
                          ? const SizedBox(
                              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.create_new_folder_outlined),
                      label: const Text('إنشاء مجلد جديد'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          _SectionCard(
            title: 'إعدادات عامة',
            children: [
              TextField(
                controller: _appNameController,
                onEditingComplete: _persistTextFields,
                decoration: const InputDecoration(labelText: 'اسم التطبيق'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _startingSerialController,
                keyboardType: TextInputType.number,
                onEditingComplete: _persistTextFields,
                decoration: const InputDecoration(labelText: 'رقم بداية الرديف'),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('السماح بتعديل الرديف يدوياً'),
                value: settings.manualSerialEditable,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).update((s) => s.copyWith(manualSerialEditable: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('السماح بإدخال مدين له ومدين عليه معاً'),
                value: settings.allowBothAmounts,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).update((s) => s.copyWith(allowBothAmounts: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('مزامنة تلقائية عند توفر الإنترنت'),
                value: settings.autoSync,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).update((s) => s.copyWith(autoSync: v)),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: settings.currency,
                decoration: const InputDecoration(labelText: 'العملة الافتراضية'),
                items: const [
                  DropdownMenuItem(value: 'EGP', child: Text('جنيه مصري (EGP)')),
                  DropdownMenuItem(value: 'IQD', child: Text('دينار عراقي (IQD)')),
                  DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
                  DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
                  DropdownMenuItem(value: 'AED', child: Text('درهم إماراتي (AED)')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref.read(settingsProvider.notifier).update((s) => s.copyWith(currency: v));
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ThemeMode>(
                initialValue: settings.themeMode,
                decoration: const InputDecoration(labelText: 'المظهر'),
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('حسب النظام')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('فاتح')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('داكن')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref.read(settingsProvider.notifier).update((s) => s.copyWith(themeMode: v));
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
