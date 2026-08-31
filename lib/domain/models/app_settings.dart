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
  final bool autoSync;

  bool get isSheetsConfigured => spreadsheetId.trim().isNotEmpty;
  bool get isDriveConfigured => driveFolderId.trim().isNotEmpty;
  bool get isFullyConfigured => isSheetsConfigured && isDriveConfigured;

  List<String> get orderedHeaderLabels =>
      AppConstants.columnOrder.map((k) => columnHeaders[k] ?? AppConstants.defaultColumnHeaders[k]!).toList();

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
      autoSync: autoSync ?? this.autoSync,
    );
  }
}
