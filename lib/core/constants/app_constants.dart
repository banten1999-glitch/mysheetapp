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

  // Header-row labels for each field. Customizable from Settings.
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

  /// Order the fields are presented in (forms, header row, mapping screen).
  /// This is display order only - the actual sheet position of each field
  /// comes from the user-editable column mapping below.
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

  /// Which spreadsheet column each field is written to. Defaults to the
  /// original fixed A..I layout, so existing sheets keep working untouched;
  /// the user can remap any field from Settings -> "تعديل الخلايا".
  static const Map<String, String> defaultColumnLetters = <String, String>{
    'serial': 'A',
    'date': 'B',
    'time': 'C',
    'statement': 'D',
    'receipt': 'E',
    'note': 'F',
    'debit': 'G',
    'credit': 'H',
    'transactionId': 'I',
  };

  /// Short, plain descriptions shown under each field on the mapping screen.
  static const Map<String, String> columnDescriptions = <String, String>{
    'serial': 'الرقم التسلسلي التلقائي للعملية',
    'date': 'تاريخ العملية',
    'time': 'وقت تسجيل العملية',
    'statement': 'وصف العملية',
    'receipt': 'رابط صورة الوصل في Google Drive',
    'note': 'ملاحظة نصية بديلة عن الصورة',
    'debit': 'المبلغ المدفوع',
    'credit': 'المبلغ المستلم',
    'transactionId': 'معرّف فريد يمنع تكرار العملية (مطلوب)',
  };

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
  static const String prefsColumnLetters = 'settings.columnLetters';
  static const String prefsAutoSync = 'settings.autoSync';
}
