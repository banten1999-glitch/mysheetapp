/// App-wide constants: OAuth scopes, storage keys, and default column setup.
class AppConstants {
  AppConstants._();

  // OAuth scopes requested from the user. `drive.file` (not full `drive`)
  // limits access to files this app itself creates - least-privilege.
  static const String sheetsScope =
      'https://www.googleapis.com/auth/spreadsheets';
  static const String driveScope = 'https://www.googleapis.com/auth/drive.file';
  static const List<String> googleScopes = <String>[sheetsScope, driveScope];

  static const String defaultAppName = 'دفتر الحسناوي';
  static const String defaultSheetName = 'Sheet1';
  static const String defaultCurrency = 'EGP';
  static const int defaultStartingSerial = 1;

  // Fixed column order written to Google Sheets (A..I). Only the *labels*
  // (header row text) are user-customizable from Settings.
  static const Map<String, String> defaultColumnHeaders = <String, String>{
    'serial': 'الرديف',
    'date': 'التاريخ',
    'time': 'الوقت',
    'statement': 'البيان',
    'receipt': 'رابط صورة الوصل',
    'note': 'النص أو الملاحظة',
    'debit': 'مدين له',
    'credit': 'مدين عليه',
    'transactionId': 'معرف العملية',
  };

  static const List<String> columnOrder = <String>[
    'serial',
    'date',
    'time',
    'statement',
    'receipt',
    'note',
    'debit',
    'credit',
    'transactionId',
  ];

  // SharedPreferences keys
  static const String prefsSpreadsheetId = 'settings.spreadsheetId';
  static const String prefsSheetName = 'settings.sheetName';
  static const String prefsDriveFolderId = 'settings.driveFolderId';
  static const String prefsStartingSerial = 'settings.startingSerial';
  static const String prefsManualSerialEditable = 'settings.manualSerialEditable';
  static const String prefsCurrency = 'settings.currency';
  static const String prefsAllowBothAmounts = 'settings.allowBothAmounts';
  static const String prefsAppName = 'settings.appName';
  static const String prefsThemeMode = 'settings.themeMode';
  static const String prefsColumnHeaders = 'settings.columnHeaders';
  static const String prefsAutoSync = 'settings.autoSync';
}
