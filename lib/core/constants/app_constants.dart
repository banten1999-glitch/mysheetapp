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
    'statement',
    'receipt',
    'note',
    'debit',
    'credit',
    'transactionId',
  ];

  /// Which spreadsheet column each field is written to, matching the
  /// account-statement layout this app is used with:
  /// B = دائن/عليه, D = مدين/له, E = ملاحظات, F = Receipt Pic,
  /// G = البيان, H = التاريخ, I = رديف. Columns A and C are left alone
  /// (only mapped cells are ever written), and the transaction id goes in
  /// J, just past the visible table. Remappable from Settings.
  static const Map<String, String> defaultColumnLetters = <String, String>{
    'serial': 'I',
    'date': 'H',
    'statement': 'G',
    'receipt': 'F',
    'note': 'E',
    'debit': 'D',
    'credit': 'B',
    'transactionId': 'J',
  };

  /// Bumped whenever [defaultColumnLetters] changes shape in a way that
  /// makes previously-saved mappings wrong; saved settings older than this
  /// are replaced by the defaults once.
  static const int columnMappingVersion = 2;

  /// Short, plain descriptions shown under each field on the mapping screen.
  static const Map<String, String> columnDescriptions = <String, String>{
    'serial': 'الرقم التسلسلي التلقائي للعملية',
    'date': 'تاريخ العملية',
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
  static const String prefsColumnMappingVersion = 'settings.columnMappingVersion';
  static const String prefsAutoSync = 'settings.autoSync';
  static const String prefsUsdRate = 'settings.usdRate';
  static const String prefsUsdRateUpdatedAt = 'settings.usdRateUpdatedAt';
}
