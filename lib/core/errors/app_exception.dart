/// Base class for all app-level exceptions. [message] is always a
/// user-presentable Arabic message - screens can show it directly.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class NoInternetException extends AppException {
  const NoInternetException([
    super.message = 'لا يوجد اتصال بالإنترنت. تم حفظ العملية محلياً وسيتم رفعها عند توفر الاتصال.',
  ]);
}

class SheetsException extends AppException {
  const SheetsException(super.message);
}

class DriveException extends AppException {
  const DriveException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class SettingsNotConfiguredException extends AppException {
  const SettingsNotConfiguredException([
    super.message = 'يجب إعداد ربط Google Sheets وGoogle Drive أولاً من صفحة الإعدادات.',
  ]);
}

class DuplicateTransactionException extends AppException {
  const DuplicateTransactionException([
    super.message = 'هذه العملية مسجلة بالفعل في الشيت.',
  ]);
}
