import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/sheet_columns.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';

/// "تعديل الخلايا" - lets the user decide which spreadsheet column each
/// field is written to. Saved settings take effect on the very next sync.
class ColumnMappingScreen extends ConsumerStatefulWidget {
  const ColumnMappingScreen({super.key});

  @override
  ConsumerState<ColumnMappingScreen> createState() => _ColumnMappingScreenState();
}

class _ColumnMappingScreenState extends ConsumerState<ColumnMappingScreen> {
  late Map<String, String> _letters;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _letters = Map<String, String>.from(
      ref.read(settingsProvider).effectiveColumnLetters,
    );
    for (final field in AppConstants.columnOrder) {
      _controllers[field] = TextEditingController(text: _letters[field]);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Per-field validation message, or null when the field is fine.
  String? _errorFor(String field, Set<String> duplicates) {
    final raw = _controllers[field]!.text;
    if (raw.trim().isEmpty) return 'مطلوب';
    if (!SheetColumns.isValid(raw)) return 'حرف غير صالح';
    if (duplicates.contains(field)) return 'مكرر';
    return null;
  }

  Set<String> get _duplicates => SheetColumns.duplicateFields(_currentInput);

  Map<String, String> get _currentInput => <String, String>{
        for (final field in AppConstants.columnOrder)
          field: _controllers[field]!.text,
      };

  bool get _isValid {
    final duplicates = _duplicates;
    return AppConstants.columnOrder
        .every((field) => _errorFor(field, duplicates) == null);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_isValid) {
      AppSnackbar.error(
        context,
        'يرجى تصحيح الحقول المميزة بالأحمر قبل الحفظ. لا يمكن تكرار نفس العمود لأكثر من حقل.',
      );
      return;
    }

    final normalized = <String, String>{
      for (final field in AppConstants.columnOrder)
        field: SheetColumns.normalize(_controllers[field]!.text)!,
    };

    await ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(columnLetters: normalized));

    if (!mounted) return;
    AppSnackbar.success(context, 'تم حفظ إعدادات الخلايا بنجاح.');
    Navigator.of(context).pop();
  }

  void _resetToDefaults() {
    setState(() {
      for (final field in AppConstants.columnOrder) {
        final value = AppConstants.defaultColumnLetters[field]!;
        _letters[field] = value;
        _controllers[field]!.text = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final duplicates = _duplicates;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('تعديل الخلايا'),
          actions: [
            IconButton(
              tooltip: 'استعادة الترتيب الافتراضي',
              icon: const Icon(Icons.restart_alt_rounded),
              onPressed: _resetToDefaults,
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    _InfoBanner(sheetName: settings.sheetName),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          for (var i = 0;
                              i < AppConstants.columnOrder.length;
                              i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _ColumnRow(
                              field: AppConstants.columnOrder[i],
                              label: settings.headerLabel(
                                AppConstants.columnOrder[i],
                              ),
                              description: AppConstants.columnDescriptions[
                                  AppConstants.columnOrder[i]]!,
                              controller:
                                  _controllers[AppConstants.columnOrder[i]]!,
                              errorText: _errorFor(
                                AppConstants.columnOrder[i],
                                duplicates,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'يدعم الأعمدة من A إلى Z ثم AA، AB وحتى ZZZ. لا يمكن استخدام نفس '
                      'العمود لأكثر من حقل حتى لا تُستبدل البيانات.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: PrimaryButton(
                  label: 'حفظ التعديلات',
                  icon: Icons.save_rounded,
                  onPressed: _isValid ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.sheetName});

  final String sheetName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.grid_on_rounded, color: AppColors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'حدّد عمود Google Sheets لكل حقل داخل التبويب "$sheetName". '
              'تُطبَّق التعديلات على العمليات التي تُرفع بعد الحفظ.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnRow extends StatelessWidget {
  const _ColumnRow({
    required this.field,
    required this.label,
    required this.description,
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  final String field;
  final String label;
  final String description;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  hasError ? errorText! : description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasError
                        ? AppColors.danger
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: hasError ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _LetterBox(
            controller: controller,
            hasError: hasError,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Compact, tappable column-letter input.
class _LetterBox extends StatelessWidget {
  const _LetterBox({
    required this.controller,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 74,
      height: 50,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        maxLength: SheetColumns.maxLetters,
        keyboardType: TextInputType.text,
        textDirection: TextDirection.ltr,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: hasError ? AppColors.danger : theme.colorScheme.primary,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
          TextInputFormatter.withFunction(
            (oldValue, newValue) => newValue.copyWith(
              text: newValue.text.toUpperCase(),
            ),
          ),
        ],
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: hasError
              ? AppColors.danger.withValues(alpha: 0.08)
              : theme.colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.08),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: BorderSide(
              color: hasError
                  ? AppColors.danger
                  : theme.colorScheme.primary.withValues(alpha: 0.35),
              width: 1.4,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: BorderSide(
              color: hasError ? AppColors.danger : theme.colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
