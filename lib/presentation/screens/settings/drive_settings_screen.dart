import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/services/google_drive_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';

class DriveSettingsScreen extends ConsumerStatefulWidget {
  const DriveSettingsScreen({super.key});

  @override
  ConsumerState<DriveSettingsScreen> createState() => _DriveSettingsScreenState();
}

class _DriveSettingsScreenState extends ConsumerState<DriveSettingsScreen> {
  late final TextEditingController _folderIdController;
  bool _testing = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _folderIdController = TextEditingController(
      text: ref.read(settingsProvider).driveFolderId,
    );
  }

  @override
  void dispose() {
    _folderIdController.dispose();
    super.dispose();
  }

  Future<void> _persist() async {
    await ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(driveFolderId: _folderIdController.text.trim()));
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
    if (!settings.isDriveConfigured) {
      AppSnackbar.error(context, 'يرجى إدخال Folder ID أولاً.');
      return;
    }

    setState(() => _testing = true);
    try {
      final client =
          await ref.read(googleAuthServiceProvider).getAuthorizedClient(account);
      try {
        await GoogleDriveService(client: client)
            .testConnection(settings.driveFolderId);
        if (mounted) {
          AppSnackbar.success(context, 'تم الاتصال بنجاح بـ Google Drive');
        }
      } finally {
        client.close();
      }
    } on AppException catch (e) {
      if (mounted) AppSnackbar.error(context, e.message);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'تعذّر الاتصال بـ Google Drive: $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _createFolder() async {
    final account = ref.read(authProvider).account;
    if (account == null) {
      AppSnackbar.error(context, 'يرجى تسجيل الدخول أولاً.');
      return;
    }

    setState(() => _creating = true);
    try {
      final client =
          await ref.read(googleAuthServiceProvider).getAuthorizedClient(account);
      try {
        final name = ref.read(settingsProvider).appName;
        final id = await GoogleDriveService(
          client: client,
        ).createFolder('وصولات $name');
        _folderIdController.text = id;
        await _persist();
        if (mounted) {
          setState(() {});
          AppSnackbar.success(context, 'تم إنشاء مجلد جديد وربطه بالتطبيق.');
        }
      } finally {
        client.close();
      }
    } on AppException catch (e) {
      if (mounted) AppSnackbar.error(context, e.message);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'تعذّر إنشاء المجلد: $e');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('إعدادات الصور')),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              GlassCard(
                child: AppTextField(
                  label: 'Google Drive Folder ID',
                  controller: _folderIdController,
                  icon: Icons.folder_rounded,
                  hint: 'الجزء الأخير من رابط المجلد',
                  textDirection: TextDirection.ltr,
                  onChanged: (_) => _persist(),
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
                label: 'إنشاء مجلد جديد',
                icon: Icons.create_new_folder_rounded,
                isLoading: _creating,
                onPressed: _createFolder,
              ),
              const SizedBox(height: 20),
              Text(
                'تُرفع صور الوصولات إلى هذا المجلد، وتُضبط صلاحيتها تلقائياً بحيث '
                'يمكن لأي شخص لديه الرابط عرضها، ثم يُحفظ الرابط في الشيت.',
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
