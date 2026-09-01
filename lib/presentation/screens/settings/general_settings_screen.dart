import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_card.dart';

class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() =>
      _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
  late final TextEditingController _appNameController;
  late final TextEditingController _startingSerialController;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _appNameController = TextEditingController(text: s.appName);
    _startingSerialController = TextEditingController(
      text: s.startingSerial.toString(),
    );
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _startingSerialController.dispose();
    super.dispose();
  }

  void _persistText() {
    ref.read(settingsProvider.notifier).update(
          (s) => s.copyWith(
            appName: _appNameController.text.trim().isEmpty
                ? s.appName
                : _appNameController.text.trim(),
            startingSerial:
                int.tryParse(_startingSerialController.text.trim()) ??
                    s.startingSerial,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('الإعدادات العامة')),
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
                      label: 'اسم التطبيق',
                      controller: _appNameController,
                      icon: Icons.badge_rounded,
                      onChanged: (_) => _persistText(),
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'رقم بداية الرديف',
                      controller: _startingSerialController,
                      icon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => _persistText(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  children: [
                    _SwitchRow(
                      title: 'تعديل الرديف يدوياً',
                      subtitle: 'السماح بتغيير الرقم التسلسلي عند الإضافة',
                      icon: Icons.edit_note_rounded,
                      value: settings.manualSerialEditable,
                      onChanged: (v) => notifier.update(
                        (s) => s.copyWith(manualSerialEditable: v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SwitchRow(
                      title: 'مدين له ومدين عليه معاً',
                      subtitle: 'السماح بإدخال المبلغين في نفس العملية',
                      icon: Icons.swap_horiz_rounded,
                      value: settings.allowBothAmounts,
                      onChanged: (v) =>
                          notifier.update((s) => s.copyWith(allowBothAmounts: v)),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SwitchRow(
                      title: 'المزامنة التلقائية',
                      subtitle: 'رفع العمليات المعلّقة عند عودة الإنترنت',
                      icon: Icons.cloud_sync_rounded,
                      value: settings.autoSync,
                      onChanged: (v) =>
                          notifier.update((s) => s.copyWith(autoSync: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: settings.currency,
                      decoration: const InputDecoration(
                        labelText: 'العملة الافتراضية',
                        prefixIcon: Icon(Icons.payments_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'EGP', child: Text('جنيه مصري (EGP)')),
                        DropdownMenuItem(value: 'IQD', child: Text('دينار عراقي (IQD)')),
                        DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
                        DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
                        DropdownMenuItem(value: 'AED', child: Text('درهم إماراتي (AED)')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          notifier.update((s) => s.copyWith(currency: v));
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<ThemeMode>(
                      initialValue: settings.themeMode,
                      decoration: const InputDecoration(
                        labelText: 'المظهر',
                        prefixIcon: Icon(Icons.dark_mode_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('حسب النظام'),
                        ),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('فاتح')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('داكن')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          notifier.update((s) => s.copyWith(themeMode: v));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      secondary: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 15)),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
