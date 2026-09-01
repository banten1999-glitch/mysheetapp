import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../providers/settings_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/ms_logo.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('معلومات التطبيق')),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.18),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const MsLogo(size: 88),
                    ),
                    const SizedBox(height: 18),
                    Text(settings.appName, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      'إدارة العمليات المالية عبر Google Sheets',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'الإصدار',
                      value: _info == null
                          ? '...'
                          : '${_info!.version} (${_info!.buildNumber})',
                    ),
                    const Divider(height: 1),
                    _InfoRow(
                      label: 'معرّف التطبيق',
                      value: _info?.packageName ?? '...',
                    ),
                    const Divider(height: 1),
                    _InfoRow(
                      label: 'الشيت المرتبط',
                      value: settings.isSheetsConfigured ? 'مرتبط' : 'غير مرتبط',
                    ),
                    const Divider(height: 1),
                    _InfoRow(
                      label: 'مجلد الصور',
                      value: settings.isDriveConfigured ? 'مرتبط' : 'غير مرتبط',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'يعمل التطبيق دون اتصال ويحفظ العمليات محلياً، ثم يزامنها تلقائياً '
                'مع Google Sheets وGoogle Drive عند توفر الإنترنت.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
