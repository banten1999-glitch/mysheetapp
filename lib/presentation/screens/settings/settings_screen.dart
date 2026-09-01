import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/settings_tile.dart';
import 'about_screen.dart';
import 'column_mapping_screen.dart';
import 'drive_settings_screen.dart';
import 'general_settings_screen.dart';
import 'sheets_settings_screen.dart';

/// Settings hub. Each area lives on its own focused page, reached from the
/// cards below, instead of one long scrolling form.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final account = ref.watch(authProvider).account;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('الإعدادات')),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _AccountCard(
                name: account?.displayName,
                email: account?.email,
                photoUrl: account?.photoUrl,
                onSignOut: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
              ),
              const SizedBox(height: 20),
              _SectionLabel('إعدادات الربط'),
              SettingsTile(
                title: 'تعديل الخلايا',
                subtitle: 'تحديد عمود Google Sheets لكل حقل',
                icon: Icons.grid_view_rounded,
                gradient: const LinearGradient(
                  colors: [AppColors.violet, AppColors.blue],
                ),
                onTap: () => _open(context, const ColumnMappingScreen()),
              ),
              SettingsTile(
                title: 'إعدادات Google Sheets',
                subtitle: settings.isSheetsConfigured
                    ? 'التبويب: ${settings.sheetName}'
                    : 'لم يتم الربط بعد',
                icon: Icons.table_chart_rounded,
                statusOk: settings.isSheetsConfigured,
                onTap: () => _open(context, const SheetsSettingsScreen()),
              ),
              SettingsTile(
                title: 'إعدادات الصور',
                subtitle: settings.isDriveConfigured
                    ? 'مجلد Google Drive مرتبط'
                    : 'لم يتم تحديد مجلد',
                icon: Icons.image_rounded,
                gradient: const LinearGradient(
                  colors: [AppColors.cyan, AppColors.success],
                ),
                statusOk: settings.isDriveConfigured,
                onTap: () => _open(context, const DriveSettingsScreen()),
              ),
              const SizedBox(height: 12),
              _SectionLabel('التطبيق'),
              SettingsTile(
                title: 'الإعدادات العامة',
                subtitle: 'الرديف، العملة، المظهر، المزامنة',
                icon: Icons.tune_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), AppColors.violet],
                ),
                onTap: () => _open(context, const GeneralSettingsScreen()),
              ),
              SettingsTile(
                title: 'معلومات التطبيق',
                subtitle: settings.appName,
                icon: Icons.info_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                ),
                onTap: () => _open(context, const AboutScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.onSignOut,
  });

  final String? name;
  final String? email;
  final String? photoUrl;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.surface,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null
                  ? Icon(Icons.person_rounded, color: theme.colorScheme.primary)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name ?? email ?? 'غير مسجل الدخول',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    email!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
            color: AppColors.danger,
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}
