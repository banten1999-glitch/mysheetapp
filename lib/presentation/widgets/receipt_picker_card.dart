import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final XFile? picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 2000);
    if (picked != null) {
      onImagePicked(File(picked.path));
    }
  }

  Future<void> _showSourceSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('التقاط صورة بالكاميرا'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pick(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('اختيار صورة من المعرض'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pick(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (image == null && existingRemoteUrl != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('توجد صورة وصل مرفوعة مسبقاً'),
          subtitle: const Text('اضغط للعرض، أو استبدلها بصورة جديدة'),
          onTap: () async {
            final uri = Uri.tryParse(existingRemoteUrl!);
            if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.sync_alt),
                tooltip: 'استبدال الصورة',
                onPressed: () => _showSourceSheet(context),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'حذف الصورة',
                onPressed: onImageRemoved,
              ),
            ],
          ),
        ),
      );
    }

    if (image == null) {
      return OutlinedButton.icon(
        onPressed: () => _showSourceSheet(context),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('إضافة صورة الوصل'),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
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
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                tooltip: 'حذف الصورة',
                onPressed: onImageRemoved,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
