import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:http/http.dart' as http;

import '../../core/errors/app_exception.dart';

/// Uploads receipt images to a user-chosen Google Drive folder and makes
/// them viewable by anyone with the link.
class GoogleDriveService {
  GoogleDriveService({required gapis.AuthClient client}) : _api = drive.DriveApi(client);

  final drive.DriveApi _api;

  Future<void> testConnection(String folderId) async {
    try {
      final file = await _api.files.get(folderId, $fields: 'id, name, mimeType') as drive.File;
      if (file.mimeType != 'application/vnd.google-apps.folder') {
        throw const DriveException('المعرّف المدخل ليس لمجلد Google Drive.');
      }
    } on DriveException {
      rethrow;
    } catch (e) {
      throw DriveException('تعذّر الوصول إلى مجلد Google Drive. تحقق من Folder ID والصلاحيات.\n($e)');
    }
  }

  Future<String> createFolder(String name, {String? parentId}) async {
    try {
      final folder = drive.File()
        ..name = name
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = parentId != null ? [parentId] : null;
      final created = await _api.files.create(folder);
      return created.id!;
    } catch (e) {
      throw DriveException('تعذّر إنشاء مجلد جديد في Google Drive.\n($e)');
    }
  }

  /// Uploads [file] to [folderId], grants "anyone with the link: viewer",
  /// and returns a shareable view link.
  Future<UploadedReceipt> uploadReceipt({
    required File file,
    required String fileName,
    required String folderId,
  }) async {
    try {
      final length = await file.length();
      final media = drive.Media(file.openRead(), length, contentType: 'image/jpeg');
      final metadata = drive.File()
        ..name = fileName
        ..parents = [folderId];

      final created = await _api.files.create(metadata, uploadMedia: media);
      final fileId = created.id;
      if (fileId == null) {
        throw const DriveException('فشل رفع الصورة إلى Google Drive.');
      }

      await _api.permissions.create(
        drive.Permission(type: 'anyone', role: 'reader'),
        fileId,
      );

      final refreshed = await _api.files.get(
        fileId,
        $fields: 'id, webViewLink, webContentLink',
      ) as drive.File;

      final link = refreshed.webViewLink ?? 'https://drive.google.com/file/d/$fileId/view?usp=sharing';
      return UploadedReceipt(fileId: fileId, url: link);
    } on DriveException {
      rethrow;
    } on http.ClientException catch (e) {
      throw DriveException('فشل الاتصال بـ Google Drive أثناء رفع الصورة.\n($e)');
    } catch (e) {
      throw DriveException('فشل رفع صورة الوصل إلى Google Drive.\n($e)');
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      await _api.files.delete(fileId);
    } catch (e) {
      throw DriveException('فشل حذف صورة الوصل من Google Drive.\n($e)');
    }
  }
}

class UploadedReceipt {
  const UploadedReceipt({required this.fileId, required this.url});

  final String fileId;
  final String url;
}
