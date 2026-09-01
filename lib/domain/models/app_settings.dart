import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class AppSettings {
  const AppSettings({
    this.spreadsheetId = '',
    this.sheetName = AppConstants.defaultSheetName,
    this.driveFolderId = '',
    this.startingSerial = AppConstants.defaultStartingSerial,
    this.manualSerialEditable = false,
    this.currency = AppConstants.defaultCurrency,
    this.allowBothAmounts = false,
    this.appName = AppConstants.defaultAppName,
    this.themeMode = ThemeMode.system,
    this.columnHeaders = AppConstants.defaultColumnHeaders,
    this.columnLetters = AppConstants.defaultColumnLetters,
    this.autoSync = true,
  });

  final String spreadsheetId;
  final String sheetName;
  final String driveFolderId;
  final int startingSerial;
  final bool manualSerialEditable;
  final String currency;
  final bool allowBothAmounts;
  final String appName;
  final ThemeMode themeMode;
  final Map<String, String> columnHeaders;

  /// Field key -> spreadsheet column letter ("A", "B", ... "AA").
  final Map<String, String> columnLetters;
  final bool autoSync;

  bool get isSheetsConfigured => spreadsheetId.trim().isNotEmpty;
  bool get isDriveConfigured => driveFolderId.trim().isNotEmpty;
  bool get isFullyConfigured => isSheetsConfigured && isDriveConfigured;

  String headerLabel(String field) =>
      columnHeaders[field] ?? AppConstants.defaultColumnHeaders[field] ?? field;

  String columnLetter(String field) =>
      columnLetters[field] ?? AppConstants.defaultColumnLetters[field] ?? 'A';

  /// Header labels keyed by field, ready to be placed at mapped columns.
  Map<String, Object?> get headerValuesByField => <String, Object?>{
        for (final field in AppConstants.columnOrder) field: headerLabel(field),
      };

  /// Full mapping with any missing field filled in from the defaults.
  Map<String, String> get effectiveColumnLetters => <String, String>{
        for (final field in AppConstants.columnOrder) field: columnLetter(field),
      };

  AppSettings copyWith({
    String? spreadsheetId,
    String? sheetName,
    String? driveFolderId,
    int? startingSerial,
    bool? manualSerialEditable,
    String? currency,
    bool? allowBothAmounts,
    String? appName,
    ThemeMode? themeMode,
    Map<String, String>? columnHeaders,
    Map<String, String>? columnLetters,
    bool? autoSync,
  }) {
    return AppSettings(
      spreadsheetId: spreadsheetId ?? this.spreadsheetId,
      sheetName: sheetName ?? this.sheetName,
      driveFolderId: driveFolderId ?? this.driveFolderId,
      startingSerial: startingSerial ?? this.startingSerial,
      manualSerialEditable: manualSerialEditable ?? this.manualSerialEditable,
      currency: currency ?? this.currency,
      allowBothAmounts: allowBothAmounts ?? this.allowBothAmounts,
      appName: appName ?? this.appName,
      themeMode: themeMode ?? this.themeMode,
      columnHeaders: columnHeaders ?? this.columnHeaders,
      columnLetters: columnLetters ?? this.columnLetters,
      autoSync: autoSync ?? this.autoSync,
    );
  }
}
