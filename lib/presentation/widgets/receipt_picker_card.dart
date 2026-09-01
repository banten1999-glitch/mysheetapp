import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class ReceiptPickerCard extends StatelessWidget {
  const ReceiptPickerCard({
    super.key,
    required this.image,
    required this.onImagePicked,
    required this.onImageRemoved,
    this.existingRemoteUrl,
  });

  final File? image;
  final ValueChanged<File> onImagePicked;
  final VoidCallback onImageRemoved;

  /// URL of an already-uploaded receipt (edit flow) - shown as a compact
  /// "view/replace/remove" card until the user picks a new local image.
  final String? existingRemoteUrl;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked != null) onImagePicked(File(picked.path));
  }

  Future<void> _showSourceSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text('إضافة صورة الوصل', style: theme.textTheme.titleMedium),
                const SizedBox(height: 18),
                _SourceOption(
                  icon: Icons.photo_camera_rounded,
                  label: 'التقاط صورة بالكاميرا',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pick(context, ImageSource.camera);
                  },
                ),
                const SizedBox(height: 10),
                _SourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'اختيار صورة من المعرض',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pick(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (image == null && existingRemoteUrl != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'صورة وصل مرفوعة',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  Text(
                    'اضغط للعرض أو استبدلها',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              tooltip: 'عرض',
              onPressed: () async {
                final uri = Uri.tryParse(existingRemoteUrl!);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.sync_alt_rounded, size: 20),
              tooltip: 'استبدال',
              onPressed: () => _showSourceSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppColors.danger,
              tooltip: 'حذف',
              onPressed: onImageRemoved,
            ),
          ],
        ),
      );
    }

    if (image == null) {
      return InkWell(
        onTap: () => _showSourceSheet(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          height: 108,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_rounded,
                size: 26,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'إضافة صورة الوصل',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'كاميرا أو معرض',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.file(image!, fit: BoxFit.cover, width: double.infinity),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onImageRemoved,
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.close_rounded, color: Colors.white, size: 19),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _showSourceSheet(context),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.sync_alt_rounded, color: Colors.white, size: 19),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
